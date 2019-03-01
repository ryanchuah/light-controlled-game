const int max_ADC_value = 1023;
const int one_third_max_ADC = max_ADC_value/3;
const int two_thirds_max_ADC = max_ADC_value * 2 / 3;
  
void setup() {
  Serial.begin(9600);
  pinMode(11, OUTPUT);
  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
}

void loop() {
  int input;
  input = analogRead(A0);
  Serial.println(input);
  if (input >= 0 && input < one_third_max_ADC){
    digitalWrite(11, HIGH);
    digitalWrite(12, LOW);
    digitalWrite(13, LOW);
  } else if (input >= one_third_max_ADC && input < two_thirds_max_ADC){
    digitalWrite(12, HIGH);
    digitalWrite(11, LOW);
    digitalWrite(13, LOW);
  } else if (input >= two_thirds_max_ADC && input < max_ADC_value){
    digitalWrite(13, HIGH);
    digitalWrite(11, LOW);
    digitalWrite(12, LOW);
  }
  delay(50);
}
