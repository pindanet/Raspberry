#!/usr/bin/python3
from gpiozero import MotionSensor
from picamera import PiCamera
import time
import os

pir = MotionSensor(4)
camera = PiCamera()
camera.rotation = 180
motionfolder = "/var/www/html/motion/fotos/"

count = 0
now = 0
previous = 0

def logme( str ):
  print (time.asctime( time.localtime(now)), str)
  return

while True:
  pir.wait_for_motion()
  count += 1
  previous = now
  now = time.time()
  logme("Motion! " + time.asctime( time.localtime(now)))
  logme (str(round(now - previous)) + "s between previous detected movement " + str(count))

  files = []
  for entry in os.scandir(motionfolder):
    "print(entry.name, entry.stat().st_ctime)"
    files.append(entry.name)

  if len(files) > 100:
    print(len(files))
    files.sort()
    oldest = motionfolder + files[0]
    os.remove(oldest)
    print (oldest + " removed")

  filename = motionfolder + time.strftime("%Y %m %d %H:%M:%S") + ".jpg"
  print(filename)
  camera.capture(filename)

  pir.wait_for_no_motion()
  logme("No Motion!")
