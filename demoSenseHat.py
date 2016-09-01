# x11vnc
# SoftAP

from sense_hat import SenseHat
from time import sleep

sense = SenseHat()
sense.low_light = True
led_loop = [4, 5, 6, 7, 15, 23, 31, 39, 47, 55, 63, 62, 61, 60, 59, 58, 57, 56, 48, 40, 32, 24, 16, 8, 0, 1, 2, 3]
prev_x = 0
prev_y = 0

while True:
    sense.set_rotation(180)
    sense.clear()
     
    r = 32
    g = 32
    b = 200
     
    # Eyes
    sense.set_pixel(2, 1, r, g, b)
    sense.set_pixel(5, 1, r, g, b)
     
    # Nose
    sense.set_pixel(3, 3, r+223, g, b-100)
    sense.set_pixel(4, 3, r+223, g, b-100)
     
    # Mouth
    sense.set_pixel(1, 5, 255, 255, 0)
    sense.set_pixel(2, 6, 255, 255, 0)
    sense.set_pixel(3, 6, 255, 255, 0)
    sense.set_pixel(4, 6, 255, 255, 0)
    sense.set_pixel(5, 6, 255, 255, 0)
    sense.set_pixel(6, 5, 255, 255, 0)
    sense.set_pixel(1, 4, 255, 255, 0)
    sense.set_pixel(6, 4, 255, 255, 0)

    for i in range(0, 5):
        sense.set_pixel(5, 1, r-32, g-32, b-32)
        for offset in led_loop:
            y = offset // 8  # row
            x = offset % 8  # column
            if x != prev_x or y != prev_y:
                sense.set_pixel(prev_x, prev_y, 0, 0, 0)

            sense.set_pixel(x, y, 0, 255, 0)

            prev_x = x
            prev_y = y
            sleep(0.1)
        sense.set_pixel(5, 1, r, g, b)
        for offset in led_loop:
            y = offset // 8  # row
            x = offset % 8  # column
            if x != prev_x or y != prev_y:
                sense.set_pixel(prev_x, prev_y, 0, 0, 0)

            sense.set_pixel(x, y, 0, 255, 0)

            prev_x = x
            prev_y = y
            sleep(0.1)
        
    t = sense.get_temperature() + 273.15
    t = (t - 32)/1.8
    p = sense.get_pressure()
    h = sense.get_humidity()

    t = round(t, 1)
    p = round(p, 1)
    h = round(h, 1)

    print("Deze Raspberry Pi meet de temperatuur ({0} graden) en de luchtdruk ({1} hPa).".format(t,p))
    sense.show_message("Deze Raspberry Pi meet de temperatuur ({0} graden) en de luchtdruk ({1} hPa).".format(t,p), text_colour=[0,255,0])

#    sense.set_rotation(180)
