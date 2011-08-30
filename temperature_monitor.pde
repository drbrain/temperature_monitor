#include <SoftwareSerial.h>
#include "DHT22.h"

#define XBee_rx_PIN 2
#define XBee_tx_PIN 3
#define DHT22_PIN 7
#define interval 2

DHT22 temp_sensor(DHT22_PIN);
SoftwareSerial XBee(XBee_rx_PIN, XBee_tx_PIN);

void setup(void)
{
  pinMode(XBee_rx_PIN, INPUT);
  pinMode(XBee_tx_PIN, OUTPUT);

  XBee.begin(9600);

  Serial.begin(9600);
}

void loop(void)
{
  DHT22_ERROR_t errorCode;
  char out[40] = "";

  delay(interval * 1000);
  errorCode = temp_sensor.readData();
  switch(errorCode)
  {
    case DHT_ERROR_NONE:
      snprintf(out, 40, "%5iC %5i%%",
              temp_sensor.getTemperatureC(), temp_sensor.getHumidity());

      Serial.println(out);
      XBee.println(out);
      break;
    case DHT_ERROR_CHECKSUM:
      snprintf(out, 40, "check sum error %5iC %5i%%",
              temp_sensor.getTemperatureC(), temp_sensor.getHumidity());

      Serial.println(out);
      XBee.println(out);
      break;
    case DHT_BUS_HUNG:
      Serial.println("BUS Hung");
      XBee.println("BUS Hung");
      break;
    case DHT_ERROR_NOT_PRESENT:
      Serial.println("Not Present");
      XBee.println("Not Present");
      break;
    case DHT_ERROR_ACK_TOO_LONG:
      Serial.println("ACK timeout");
      XBee.println("ACK timeout");
      break;
    case DHT_ERROR_SYNC_TIMEOUT:
      Serial.println("Sync Timeout");
      XBee.println("Sync Timeout");
      break;
    case DHT_ERROR_DATA_TIMEOUT:
      Serial.println("Data Timeout");
      XBee.println("Data Timeout");
      break;
    case DHT_ERROR_TOOQUICK:
      Serial.println("Polled too quick");
      XBee.println("Polled too quick");
      break;
  }
}

