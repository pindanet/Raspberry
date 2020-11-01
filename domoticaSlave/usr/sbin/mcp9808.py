#!/usr/bin/python3
import time
import board
import busio
import adafruit_mcp9808

i2c_bus = busio.I2C(board.SCL, board.SDA)

# To initialise using the default address:
mcp = adafruit_mcp9808.MCP9808(i2c_bus)

# To initialise using a specified address:
# Necessary when, for example, connecting A0 to VDD to make address=0x19
# mcp = adafruit_mcp9808.MCP9808(i2c_bus, address=0x19)

tempC = mcp.temperature
print("{}".format(tempC))
