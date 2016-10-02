#!/usr/bin/python
# -*- coding: UTF-8 -*-# enable debugging
import cgitb
import bme280
cgitb.enable()
print("Content-Type: text/html;charset=utf-8")
print

temperature,pressure,humidity = bme280.readBME280All()
print "Temperatuur: {0:.1f} °C, Luchtdruk: {1:.0f} hPa, Vochtigheid: {2:.0f} %".format(temperature, pressure, humidity)
