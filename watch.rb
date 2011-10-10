require 'rubygems'
require 'serialport'

device = Dir['/dev/tty.usbserial*'].first

class Watcher

  OK = 0
  BUS_HUNG = 1
  NOT_PRESENT = 2
  ACK_TIMEOUT = 3
  SYNC_TIMEOUT = 4
  DATA_TIMEOUT = 5
  CHECKSUM = 6
  TOO_QUICK = 7

  def initialize device
    puts "listening on #{device}"
    @xbee = SerialPort.new device, 9600, 8, 1, SerialPort::NONE
  end

  def get_int
    @xbee.read(2).unpack('n').first
  end

  def get_byte
    @xbee.read(1).unpack('C').first
  end

  def sync
    state = [@xbee.get_byte]
    loop do
      state << @xbee.get_byte

      break if state.last(2) == [0xFF, 0x00]
    end
  end

  def display_data
    loop do
      sync

      status = get_int

      case status
      when OK then
        temp  = get_int / 10.0
        humid = get_int / 10.0

        puts "%s %4gC %4g%%" % [Time.now, temp, humid]
      when BUS_HUNG then
        puts "Bus hung"
      when NOT_PRESENT then
        puts "Not present"
      when ACK_TIMEOUT then
        puts "ACK timeout"
      when SYNC_TIMEOUT then
        puts "Sync timeout"
      when DATA_TIMEOUT then
        puts "Data timeout"
      when CHECKSUM then
        puts "Checksum error"
      when TOO_QUICK then
        puts "Polled too quick"
      else
        puts "Garbage status: #{status.inspect}"
      end
    end
  end
end

watcher = Watcher.new device
watcher.display_data

