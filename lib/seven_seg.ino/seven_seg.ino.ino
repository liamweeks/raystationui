#include <WiFi.h>
#include <time.h>
#include "SevSeg.h"

SevSeg sevseg;

unsigned long previousMillis = 0;
const long interval = 1000; // 1 second

// WiFi Credentials
const char* ssid = "YOUR_NETWORK_HERE";
const char* password = "YOUR_PASSWORD_HERE";

// Timezone: Ottawa is UTC-5 and DST is +1
const long gmtOffset_sec = -5 * 3600; // UTC-5
const int daylightOffset_sec = 3600;  // +1 hour for DST

void setupDisplay() {
    byte numDigits = 4;
    byte digitPins[] = {2, 3, 4, 5};
    byte segmentPins[] = {
        6,  /*a*/
        7,  /*b*/
        8,  /*c*/
        9,  /*d*/
        10, /*e*/
        11, /*f*/
        12, /*g*/
        13  /*dp*/
    };
    bool resistors_on_segments = 0; // resistors on digit pins

    sevseg.begin(COMMON_CATHODE, numDigits, digitPins, segmentPins, resistors_on_segments);
    sevseg.setBrightness(90);
}

void connectWiFiAndTime() {
    Serial.print("Connecting to WiFi: ");
    Serial.println(ssid);
    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println();
    Serial.print("WiFi connected. IP: ");
    Serial.println(WiFi.localIP());

    // Configure NTP
    configTime(
        gmtOffset_sec,
        daylightOffset_sec,
        "pool.ntp.org",
        "time.nist.gov"
    );

    Serial.print("Waiting for time");
    struct tm timeinfo;
    while (!getLocalTime(&timeinfo)) {
        Serial.print(".");
        delay(500);
    }
    Serial.println();
    Serial.println("Time synchronized from NTP:");
    Serial.println(&timeinfo, "%Y-%m-%d %H:%M:%S");
}

void setup() {
    Serial.begin(9600);
    delay(1000);

    setupDisplay();
    connectWiFiAndTime();
}

void loop() {
    unsigned long currentMillis = millis();

    // Multiplex the 7-segment display – must be called very often
    sevseg.refreshDisplay();

    // Update the displayed time once per second
    if (currentMillis - previousMillis >= interval) {
        previousMillis = currentMillis;

        struct tm timeinfo;
        if (getLocalTime(&timeinfo)) {
            int hour = timeinfo.tm_hour;
            int minute = timeinfo.tm_min;

            // Display as HHMM
            int displayValue = hour * 100 + minute + 1000;

            // Note: leading zeros (e.g. 09:05) will show as 905
            sevseg.setNumber(displayValue, -1);

            Serial.print("Current time: ");
            Serial.println(&timeinfo, "%Y-%m-%d %H:%M:%S");
        } else {
            Serial.println("Failed to obtain time");
        }
    }
}
