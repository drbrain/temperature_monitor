require 'pid'
require 'appscript'

class IndigoControl

  def self.run args = ARGV
    new.run
  end

  def initialize
    @app = Appscript.app 'IndigoServer'

    @fireplace = @app.devices['Fireplace']
    @living_room_temperature = get_variable 'Living_Room_Temperature'
    @desired_temperature = get_variable 'Desired_Temperature'
    @fire_position = get_variable 'Fire_Position'

    @pid = PID.new get_set_point

    # Ziegler-Nichols
    #@pid.proportional_gain = 1.0 * 0.6
    #@pid.integral_gain = 2 * @pid.proportional_gain / 60
    #@pid.derivative_gain = 0.6 * @pid.integral_gain / 8
  end

  def get_set_point
    @desired_temperature.value.get.to_f
  end

  def get_temperature
    @living_room_temperature.value.get.to_f
  end

  def get_variable name
    begin
      @app.variables[name].value.get # check for existence
      @app.variables[name]
    rescue Appscript::CommandError
      @app.make new: :variable, with_properties: { name: name }
    end
  end

  def on
    return if @fireplace.binary_outputs.get.first

    @fireplace.binary_outputs.set [true]
  end

  def off
    return unless @fireplace.binary_outputs.get.first

    @fireplace.binary_outputs.set [false]
  end

  def run
    @pid.loop do |position|
      @fire_position.value.set position
      @pid.set_point = get_set_point

      puts "position: %3.2f set point: %3.2f" % [position, @pid.set_point]

      if position < -0.2 then
        off
      elsif position > 0.2 then
        on
      end

      sleep 60

      get_temperature
    end
  end

end

