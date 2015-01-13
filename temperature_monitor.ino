#include <SoftwareSerial.h>
#include "DHT22.h"

#define XBee_rx_PIN 2
#define XBee_tx_PIN 3
#define DHT22_PIN 4
#define interval 15

DHT22 temp_sensor(DHT22_PIN);
SoftwareSerial XBee(XBee_rx_PIN, XBee_tx_PIN);

void setup(void)
{
  pinMode(XBee_rx_PIN, INPUT);
  pinMode(XBee_tx_PIN, OUTPUT);

  XBee.begin(9600);

  Serial.begin(9600);

  delay(2000);
}

void loop(void)
{
  DHT22_ERROR_t error_code;

  error_code = temp_sensor.readData();

  write_int(0xFF00); // sync
  write_int(error_code);

  switch(error_code)
  {
    case DHT_ERROR_NONE:
    case DHT_ERROR_CHECKSUM:
      write_int(temp_sensor.getTemperatureC());
      write_int(temp_sensor.getHumidity());
      break;
  }

  delay(interval * 1000);
}

void write_int(int value) {
  XBee.write(value >> 8);
  XBee.write(value & 0xff);
}

