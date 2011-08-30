require 'rubygems'
require 'serialport'

OK = 0
BUS_HUNG = 1
NOT_PRESENT = 2
ACK_TIMEOUT = 3
SYNC_TIMEOUT = 4
DATA_TIMEOUT = 5
CHECKSUM = 6
TOO_QUICK = 7

device = Dir['/dev/tty.usbserial*'].first

puts "listening on #{device}"
xbee = SerialPort.new device, 9600, 8, 1, SerialPort::NONE

loop do
  case val = xbee.read(2).unpack('n').first
  when 0 then
    temp, humid = xbee.read(4).unpack 'nn'
    temp = temp / 10.0
    humid = humid / 10.0

    puts "%4gC %4g%%" % [temp, humid]
  when 1 then
    puts "Bus hung"
  when 2 then
    puts "Not present"
  when 3 then
    puts "ACK timeout"
  when 4 then
    puts "Sync timeout"
  when 5 then
    puts "Data timeout"
  when 6 then
    puts "Polled too quick"
  else
    puts "garbage: #{val.inspect}"
  end
end

