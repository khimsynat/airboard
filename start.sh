#!/bin/bash
adb reverse tcp:9001 tcp:9001
adb reverse tcp:9002 tcp:9002
echo "ADB reverse set up for ports 9001 and 9002 ✅"
adb install app-release.apk
python3 main.py