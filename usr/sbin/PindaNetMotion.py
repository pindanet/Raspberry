#!/usr/bin/python3
from gpiozero import MotionSensor
from picamera import PiCamera
import time
import os

pir = MotionSensor(4)
camera = PiCamera()
camera.rotation = 180
motionfolder = "/var/www/html/motion/fotos/"
keep = 60 * 60 * 24 # Time in seconds before removing motion photo's

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

  #files = []
  for entry in os.scandir(motionfolder):
    #files.append(entry.name)
    if (now - entry.stat().st_ctime) > keep:
      fileToDelete = motionfolder + entry.name
      os.remove(fileToDelete)
      print(fileToDelete + " removed.")

  filename = motionfolder + time.strftime("%Y %m %d %H:%M:%S") + ".jpg"
  print(filename)
  # Taking picture disturbs sound
  if os.path.exists("/var/www/html/data/mpc.txt"):
    print("Music playing")
  else:
    print("No music playing")
    camera.capture(filename)

  pir.wait_for_no_motion()
  logme("No Motion!")
