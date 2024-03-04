#!/usr/bin/bash
echo "scale = 0; ($(/usr/sbin/mcp9808.py) * 1000) / 1" | bc
