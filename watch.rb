require 'rubygems'
require 'serialport'

device = Dir['/dev/tty.usbserial*'].first

puts "listening on #{device}"
xbee = SerialPort.new device, 9600, 8, 1, SerialPort::NONE

loop do
  puts xbee.gets
end

