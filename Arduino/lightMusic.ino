//Team JSJ -
//Jordan Kayse
//Jessica Yeh
//Story Zanetti

//Files to include.
#include <SPI.h>
#include <boards.h>
#include <ble_shield.h>

//Analog Input Pins.
int potentiometerPin = 1;
int photoCellPin = 0;

//PWM Digital Output Pins.
int ledREDPin = 6; 
int ledGREENPin = 10;

//Digital Input Pin.
int buttonPin = 7;

//Default values.
int potentiometerVal = 0;
int oldPotentiometerVal = -5;
int photoCellVal = 0;
byte buttonVal = LOW;
byte oldButtonVal = LOW;
bool partyMode = false;
bool playing = false;


void setup() {
  //Setup bluetooth connection.
  ble_set_name("JSJ");
  ble_begin();
  
  //Set up initial values.
  Serial.begin(57600);
  pinMode(buttonPin, INPUT);
  analogWrite(ledREDPin, 0);
  analogWrite(ledGREENPin, 0);
}

void loop() {
  
  //Get any data that was sent from the phone.
  while (ble_available()) {  
    
    //Read out command and data
    byte data0 = ble_read();
    byte data1 = ble_read();
    byte data2 = ble_read();
    byte data3 = ble_read();
    
    //Get the led values.
    byte redVal = digitalRead(ledREDPin);
    byte greenVal = digitalRead(ledGREENPin);
    
    //Set party mode.
    if (data0 == 0x01) {
      partyMode = true;
    }
    //Any other mode.
    else {
      partyMode = false;
      playing = false;
    }
    
    //Red LED, fade in.
    if (data2 == 0x11) {
      if (redVal == LOW) {
        for (int fadeValue = 0; fadeValue <= 255; fadeValue +=5) { 
          analogWrite(ledREDPin, fadeValue); 
          delay(10);   
        }   
      }    
    }
    //Red LED, fade out.
    else if (data2 == 0x10) {
      if (redVal == HIGH) {
        for (int fadeValue = 255; fadeValue >= 0; fadeValue -=5) { 
          analogWrite(ledREDPin, fadeValue);    
          delay(10);            
        }
      }
    }
    
    //Green LED, fade in.
    if (data1 == 0x21) {
      playing = true;
      if (greenVal == LOW) {
        for (int fadeValue = 0; fadeValue <= 255; fadeValue +=5) { 
          analogWrite(ledGREENPin, fadeValue); 
          delay(10);   
        } 
      }      
    }
    //Green LED, fade out.
    else if (data1 == 0x20) {
      playing = false;
      if (greenVal == HIGH) {
        for (int fadeValue = 255; fadeValue >= 0; fadeValue -=5) { 
          analogWrite(ledGREENPin, fadeValue);    
          delay(10);            
        }
      }
    }
  }
  
  //If connected to the phone.
  if (ble_connected()) {
    
    //Pulse green light when in party mode.
    if (partyMode && playing) {
      for (int fadeValue = 0; fadeValue <= 255; fadeValue +=5) { 
        analogWrite(ledGREENPin, fadeValue);    
        delay(10);            
      }
    }
    
    //Get values from sensors.  
    potentiometerVal = analogRead(potentiometerPin);
    photoCellVal = analogRead(photoCellPin);
    buttonVal = digitalRead(buttonPin);
     
    //See if button value differs. If it does, send it.
    if (buttonVal != oldButtonVal) {
      oldButtonVal = buttonVal;
      if (buttonVal == HIGH) {
        ble_write(0x0A);
        ble_write(0x01);
        ble_write(0x00);
      }
      else {
        ble_write(0x0A);
        ble_write(0x00);
        ble_write(0x00);
      }
    }
    
    //Set first potentiometer value.
    if (oldPotentiometerVal == -5) {
      oldPotentiometerVal = potentiometerVal;
    }
    //See if potentiometer value differs. If it does, send it.
    if (abs(oldPotentiometerVal - potentiometerVal) > 5) {
      oldPotentiometerVal = potentiometerVal;
      //Send the potentiometer value.
      ble_write(0x0B);
      ble_write(highByte(potentiometerVal));
      ble_write(lowByte(potentiometerVal));
    } 
    
    //Send the photo cell value.
    ble_write(0x0C);
    ble_write(highByte(photoCellVal));
    ble_write(lowByte(photoCellVal));
  }
  
  //If not connected to phone, turn of all LEDs.
  if (!ble_connected()) {
    analogWrite(ledREDPin, 0);
    analogWrite(ledGREENPin, 0);
  } 
  //Send and receive the data.
  ble_do_events();
}
