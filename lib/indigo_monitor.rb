require 'watcher'
require 'appscript'

$stdout.sync = true
$stderr.sync = true

class IndigoMonitor

  def self.run args = ARGV
    new.run
  rescue => e
    puts "#{e.message} (#{e.class})"
    sleep 60
    retry
  end

  def initialize
    @app = Appscript.app '/Library/Application Support/Perceptive Automation/Indigo 6/IndigoServer.app'

    @living_room_temperature = get_variable 'Living_Room_Temperature'
    @living_room_humidity = get_variable 'Living_Room_Humidity'
  end

  def c_to_f degrees_c
    9.0 / 5.0 * degrees_c + 32
  end

  def get_variable name
    begin
      @app.variables[name].value.get # check for existence
      @app.variables[name]
    rescue Appscript::CommandError
      @app.make new: :variable, with_properties: { name: name }
    end
  end

  def run
    loop do
      watcher.watch do |status, temp, humid|
        next unless status == Watcher::OK

        temp = c_to_f temp
        temp = "%5.1f" % temp
        @living_room_temperature.value.set temp
        @living_room_humidity.value.set humid
      end
    end
  rescue => e
    puts "#{e.message} (#{e.class})"
    sleep 1
    retry
  end

  def watcher
    device = Dir['/dev/tty.usbserial-A8004Zxd'].first
    watcher = Watcher.new device
  end

end

