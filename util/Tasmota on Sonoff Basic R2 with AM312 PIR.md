# Tasmota on Sonoff Basic R2 with AM312 PIR
## Wiring for Sonoff Basic R2 (https://tasmota.github.io/docs/Project-AM312-and-Sonoff-R2/#wiring-for-sonoff-basic-r2)

As the R2 version doesn't have GPIO14 exposed you can use GPIO3 (RX) as the AM312 data pin. GPIO2 goes high during the boot (it would toggle the switch then).

| AM312 |	ESP8255 device |
| ----- | -------------- |
| VCC |	3V3 or VCC |
| VOUT |	GPIO3 (RX) |
| GND  |	GND |

## Configuration (https://tasmota.github.io/docs/Rules/#enable-a-pir-switch-only-at-night)

Go to IP of the device, next Configuration --> Module --> set "GPIO3" to "Switch1"

Go to Console and type "SwitchMode 4" to enable toggle switch type.
    Set rule to turn off light after X amount of seconds (mentioned workaround):

    rule1 on Switch1#State=2 do backlog Power1 1; RuleTimer1 180 endon on Rules#Timer=1 do backlog Power1 0 endon
    rule1 1

Rule explanation: Switch1#State=2 - fire the event when switch1 is toggled, Power1 1 - turn on power, RuleTimer1 180 - set Timer1 to 180 seconds and start counting, Rules#Timer=1 - fire the event when Timer1 has stopped, Power1 0 - turn off power.

This rule will turn off the light after 3 minutes, if the movement will be detected prior, the timer will be restarted and will count the time from the beginning.
