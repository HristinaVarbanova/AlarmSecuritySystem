#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>
#include <WiFi.h>
#include <WebServer.h>
#include <SPI.h>
#include <MFRC522.h>
#include <ESP32Servo.h>

#define SS_PIN 5
#define RST_PIN 4

unsigned long lastDisarmTime = 0;

const char* ssid = "SmartHomeAlarm";
const char* password = "12345678";
bool armingPending = false;
unsigned long armingStartTime = 0;
unsigned long lastArmingBeepTime = 0;

const unsigned long ARM_DELAY = 20000;
const unsigned long ARM_BEEP_INTERVAL = 2000;

int wrongPinAttempts = 0;
bool pinBlocked = false;
unsigned long pinBlockStartTime = 0;
const unsigned long PIN_BLOCK_DURATION = 30000;

WebServer server(80);

LiquidCrystal_I2C lcd(0x27, 16, 2);
MFRC522 rfid(SS_PIN, RST_PIN);

const int PIR_PIN = 13;
const int BUZZER_PIN = 27;

const int SERVO_PIN = 15;
Servo doorServo;
const int LOCKED_ANGLE = 0;
const int UNLOCKED_ANGLE = 90;

const byte ROWS = 4;
const byte COLS = 4;

char keys[ROWS][COLS] = {
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};

byte rowPins[ROWS] = {32, 33, 25, 26};
byte colPins[COLS] = {14, 12, 16, 17};

byte card1[4] = {0x2A, 0x4B, 0xCF, 0x9A};
byte card2[4] = {0x97, 0x60, 0x24, 0x03};

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

String enteredCode = "";
String correctPin = "1234";

bool armed = false;
bool alarmOn = false;
bool enterPinMode = false;

unsigned long lastBeepTime = 0;
bool buzzerState = false;

void showNormalScreen(int motion) {
  lcd.clear();
  lcd.setCursor(0, 0);
  if (armed) {
    lcd.print("System: ARMED");
  } else {
    lcd.print("System: OFF  ");
  }

  lcd.setCursor(0, 1);
  if (motion == HIGH) {
    lcd.print("PIR: Motion   ");
  } else {
    lcd.print("PIR: Safe     ");
  }
}

void shortBeep(int durationMs) {
  digitalWrite(BUZZER_PIN, HIGH);
  delay(durationMs);
  digitalWrite(BUZZER_PIN, LOW);
}

void sendEventLog(String type, String message) {
  Serial.print("EVENT: ");
  Serial.print(type);
  Serial.print(" | ");
  Serial.println(message);

 
}

void handlePinBlock() {

  if (!pinBlocked) return;

  unsigned long elapsed = millis() - pinBlockStartTime;

  if (elapsed >= PIN_BLOCK_DURATION) {
    pinBlocked = false;
    wrongPinAttempts = 0;
    enteredCode = "";

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("PIN Unblocked");
    lcd.setCursor(0, 1);
    lcd.print("Try again");
    delay(1000);

    showNormalScreen(digitalRead(PIR_PIN));
    return;
  }

  int remaining = (PIN_BLOCK_DURATION - elapsed) / 1000;

  lcd.setCursor(0,0);
  lcd.print("PIN BLOCKED   ");

  lcd.setCursor(0,1);
  lcd.print("Wait ");
  lcd.print(remaining);
  lcd.print(" sec   ");
}

void activatePinBlock() {
  pinBlocked = true;
  pinBlockStartTime = millis();
  enteredCode = "";

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("PIN BLOCKED");
  lcd.setCursor(0, 1);
  lcd.print("Wait 30 sec");

  shortBeep(200);
  delay(150);
  shortBeep(200);
  delay(150);
  shortBeep(400);
}

void lockDoor() {
  doorServo.write(LOCKED_ANGLE);
}

void unlockDoor() {
  doorServo.write(UNLOCKED_ANGLE);
}

void handleArmingCountdown() {
  if (!armingPending) return;

  unsigned long now = millis();
  unsigned long elapsed = now - armingStartTime;

  if (elapsed >= ARM_DELAY) {
    armingPending = false;
    armed = true;
    lockDoor();
    sendEventLog("system_armed", "System armed and door locked");

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("System Armed");
    lcd.setCursor(0, 1);
    lcd.print("Monitoring...");

    shortBeep(800);
    showNormalScreen(digitalRead(PIR_PIN));
    return;
  }

  if (now - lastArmingBeepTime >= ARM_BEEP_INTERVAL) {
    lastArmingBeepTime = now;

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Exit in:");
    lcd.setCursor(0, 1);
    lcd.print((ARM_DELAY - elapsed) / 1000);
    lcd.print(" sec      ");

    shortBeep(120);
  }
}

void showAlarmScreen() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("!!! ALARM !!!");
  lcd.setCursor(0, 1);
  lcd.print("Press B       ");
}

void showEnterPinScreen() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter PIN:");
  lcd.setCursor(0, 1);
  for (unsigned int i = 0; i < enteredCode.length(); i++) {
    lcd.print("*");
  }
}

void handleBuzzer() {
  if (millis() - lastBeepTime >= 200) {
    lastBeepTime = millis();
    buzzerState = !buzzerState;
    digitalWrite(BUZZER_PIN, buzzerState ? HIGH : LOW);
  }
}

bool isAuthorizedCard() {
  if (rfid.uid.size != 4) return false;

  bool match1 = true;
  for (byte i = 0; i < 4; i++) {
    if (rfid.uid.uidByte[i] != card1[i]) {
      match1 = false;
      break;
    }
  }

  bool match2 = true;
  for (byte i = 0; i < 4; i++) {
    if (rfid.uid.uidByte[i] != card2[i]) {
      match2 = false;
      break;
    }
  }

  return match1 || match2;
}

void stopBuzzer() {
  digitalWrite(BUZZER_PIN, LOW);
  buzzerState = false;
}

/*void handleRoot() {
  String page = "<h1>Smart Home Security</h1>";

  if (armed)
    page += "<p>System: ARMED</p>";
  else
    page += "<p>System: OFF</p>";

  if (alarmOn)
    page += "<p>ALARM TRIGGERED</p>";

  page += "<a href=\"/arm\"><button>ARM</button></a>";
  page += "<a href=\"/disarm\"><button>DISARM</button></a>";

  server.send(200, "text/html", page);
}*/

/*void handleArm() {
  armed = false;
  armingPending = true;
  enteredCode = "";
  armingStartTime = millis();
  lastArmingBeepTime = 0;

  server.sendHeader("Location", "/");
  server.send(303);
}*/

/*void handleArm() {
  armed = false;
  armingPending = true;
  enteredCode = "";
  armingStartTime = millis();
  lastArmingBeepTime = 0;

  server.send(200, "application/json", "{\"status\":\"arming\"}");
}*/


/*void handleDisarm() {
  armed = false;
  alarmOn = false;
  armingPending = false;
  enterPinMode = false;
  wrongPinAttempts = 0;
  pinBlocked = false;
  enteredCode = "";
  lastDisarmTime = millis();

  stopBuzzer();
  unlockDoor();
  sendEventLog("door_unlocked", "System disarmed and door unlocked");

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System Off");
  lcd.setCursor(0, 1);
  lcd.print("Disarmed");

  server.sendHeader("Location", "/");
  server.send(303);
}*/

/*void handleDisarm() {
  armed = false;
  alarmOn = false;
  armingPending = false;
  enterPinMode = false;
  wrongPinAttempts = 0;
  pinBlocked = false;
  enteredCode = "";
  lastDisarmTime = millis();

  stopBuzzer();
  unlockDoor();
  sendEventLog("system_disarmed", "System disarmed from app");


  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System Off");
  lcd.setCursor(0, 1);
  lcd.print("Disarmed");

  server.send(200, "application/json", "{\"status\":\"disarmed\"}");
}

void handleStatus() {
  String json = "{";
  json += "\"armed\":";
  json += armed ? "true" : "false";
  json += ",";
  json += "\"alarmOn\":";
  json += alarmOn ? "true" : "false";
  json += ",";
  json += "\"armingPending\":";
  json += armingPending ? "true" : "false";
  json += "}";

  server.send(200, "application/json", json);
}

void setup() {
  pinMode(PIR_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  stopBuzzer();

  Serial.begin(115200);
  WiFi.softAP(ssid, password);

  SPI.begin(18, 19, 23, SS_PIN);
  rfid.PCD_Init();

  Serial.println("RFID ready");
  Serial.println("WiFi started");
  Serial.println(WiFi.softAPIP());

  //server.on("/", handleRoot);
  server.on("/arm", handleArm);
  server.on("/disarm", handleDisarm);
  server.on("/status", handleStatus);
  server.begin();

  lcd.init();
  lcd.backlight();

  doorServo.setPeriodHertz(50);
  doorServo.attach(SERVO_PIN, 500, 2400);
  lockDoor();

  lcd.setCursor(0, 0);
  lcd.print("Security System");
  lcd.setCursor(0, 1);
  lcd.print("ESP32 Starting");
  delay(1500);

  showNormalScreen(digitalRead(PIR_PIN));
}

void loop() {
  int motion = digitalRead(PIR_PIN);
  char key = keypad.getKey();

  server.handleClient();
  handleArmingCountdown();
  handlePinBlock();

  if (!armingPending && rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    if (isAuthorizedCard()) {
      wrongPinAttempts = 0;
      pinBlocked = false;
      armed = false;
      alarmOn = false;
      enterPinMode = false;
      enteredCode = "";
      stopBuzzer();
      lastDisarmTime = millis();
      unlockDoor();

      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("RFID ACCESS");
      lcd.setCursor(0, 1);
      lcd.print("DISARMED");
      sendEventLog("system_disarmed", "System disarmed by RFID");
    } else {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Unknown Card");
      lcd.setCursor(0, 1);
      lcd.print("Access Denied");
      sendEventLog("access_denied", "Unknown RFID card");
    }

    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();

    delay(500);
    showNormalScreen(digitalRead(PIR_PIN));
  }

  if (armed && motion == HIGH && !alarmOn && millis() - lastDisarmTime > 3000) {
    alarmOn = true;
    enterPinMode = false;
    enteredCode = "";
    sendEventLog("alarm_triggered", "Motion detected while system was armed");
    
    showAlarmScreen();
  }

  if (alarmOn) {
    handleBuzzer();

    if (pinBlocked && key) {
      unsigned long remaining = (PIN_BLOCK_DURATION - (millis() - pinBlockStartTime)) / 1000;

      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("PIN BLOCKED");
      lcd.setCursor(0, 1);
      lcd.print("Wait ");
      lcd.print(remaining);
      lcd.print(" sec ");

      shortBeep(100);
      delay(300);
      return;
    }

    if (key) {
      Serial.print("Key: ");
      Serial.println(key);

      if (!enterPinMode && key == 'B') {
        enterPinMode = true;
        enteredCode = "";
        armingPending = false;
        showEnterPinScreen();
      } 
      else if (enterPinMode) {
        if (key >= '0' && key <= '9') {
          if (enteredCode.length() < 8) {
            enteredCode += key;
            showEnterPinScreen();
          }
        }
        else if (key == '*') {
          enteredCode = "";
          showEnterPinScreen();
        }
        else if (key == '#') {
          if (enteredCode == correctPin) {
            wrongPinAttempts = 0;
            pinBlocked = false;
            alarmOn = false;
            armed = false;
            enterPinMode = false;
            enteredCode = "";
            stopBuzzer();
            unlockDoor();
            sendEventLog("system_disarmed", "System disarmed by PIN during alarm");
            

            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("System Off");
            lcd.setCursor(0, 1);
            lcd.print("Disarmed");
            delay(1200);
            showNormalScreen(digitalRead(PIR_PIN));
          } 
          else {
            wrongPinAttempts++;
            enteredCode = "";
            sendEventLog("wrong_pin", "Wrong PIN entered "+ String(wrongPinAttempts));

            if (wrongPinAttempts >= 3) {
              activatePinBlock();
              enterPinMode = false;
              return;
            }

            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Wrong PIN");
            lcd.setCursor(0, 1);
            lcd.print("Try again");
            delay(900);
            showEnterPinScreen();
          }
        }
      }
    }

    return;
  }

  if (pinBlocked && key) {
    unsigned long remaining = (PIN_BLOCK_DURATION - (millis() - pinBlockStartTime)) / 1000;

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("PIN BLOCKED");
    lcd.setCursor(0, 1);
    lcd.print("Wait ");
    lcd.print(remaining);
    lcd.print(" sec ");

    shortBeep(100);
    delay(300);
    return;
  }

  if (key) {
    Serial.print("Key: ");
    Serial.println(key);

    if (key >= '0' && key <= '9') {
      if (enteredCode.length() < 8) {
        enteredCode += key;
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Enter PIN:");
        lcd.setCursor(0, 1);
        for (unsigned int i = 0; i < enteredCode.length(); i++) {
          lcd.print("*");
        }
      }
    }
    else if (key == '*') {
      enteredCode = "";
      showNormalScreen(motion);
    }
    else if (key == '#') {
      if (enteredCode == correctPin) {
        wrongPinAttempts = 0;
        enteredCode = "";
        unlockDoor();

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("PIN Correct");
        delay(700);
      } 
      else {
        wrongPinAttempts++;
        enteredCode = "";
        sendEventLog("wrong_pin", "Wrong PIN entered "+ String(wrongPinAttempts));

        if (wrongPinAttempts >= 3) {
          activatePinBlock();
          return;
        }

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Wrong PIN");
        lcd.setCursor(0, 1);
        lcd.print("Try again");
        delay(900);
      }

      showNormalScreen(motion);
    }
    else if (key == 'A') {
      if (enteredCode == correctPin) {
        enteredCode = "";
        wrongPinAttempts = 0;
        armingPending = true;
        armed = false;
        armingStartTime = millis();
        lastArmingBeepTime = 0;

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Arming...");
        lcd.setCursor(0, 1);
        lcd.print("Exit now");
        delay(300);
      } else {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Enter PIN first");
        delay(1000);
        showNormalScreen(motion);
      }
    }
    else if (key == 'B') {
      if (enteredCode == correctPin) {
        wrongPinAttempts = 0;
        pinBlocked = false;
        armed = false;
        enteredCode = "";
        stopBuzzer();
        unlockDoor();
        sendEventLog("system_disarmed", "System disarmed by PIN");

        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("System Off");
        lcd.setCursor(0, 1);
        lcd.print("Disarmed");
        delay(1200);
      } else {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Enter PIN first");
        delay(1000);
      }

      showNormalScreen(motion);
    }}
  }



