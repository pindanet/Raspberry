#!/usr/bin/python3
from gpiozero import MotionSensor
import time

count = 0
now = 0
previous = 0

def logme( str ):
  print (time.asctime( time.localtime(now)), str)
  return

pir = MotionSensor(4)
while True:
  pir.wait_for_motion()
  count += 1
  previous = now
  now = time.time()
  logme("Motion! " + time.asctime( time.localtime(now)))
  logme (str(round(now - previous)) + "s between previous detected movement " + str(count))
  
  for entry in os.scandir("/var/www/html/motion/fotos/"):
    print(entry.name, entry.stat().st_ctime)
  
  pir.wait_for_no_motion()
  logme("No Motion!")
