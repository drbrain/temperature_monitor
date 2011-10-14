require 'watcher'
require 'appscript'

class IndigoMonitor

  def self.run args = ARGV
    new.run
  end

  def initialize
    device = Dir['/dev/tty.usbserial*'].first
    @watcher = Watcher.new device
    @app = Appscript.app 'IndigoServer'

    @living_room_temperature = get_variable 'Living_Room_Temperature'
    @living_room_humidity = get_variable 'Living_Room_Humidity'
  end

  def c_to_f degrees_c
    9.0 / 5.0 * dergees_c + 32
  end

  def get_variable name
    begin
      app.variables[name].value.get
    rescue Appscript::CommandError
      app.make new: :variable, with_properties: { name: name }
    end
  end

  def run
    watch do |status, temp, humid|
      next unless status == Watcher::OK

      @living_room_temperature.value.set c_to_f temp
      @living_room_humidity.value.set humid
    end
  end

end

