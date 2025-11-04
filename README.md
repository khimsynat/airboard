# AirBoard – Tablet-to-Mac Remote Drawing & Control

AirBoard is a real-time screen streaming and remote drawing app that allows your tablet to control and draw on your Mac. Perfect for presentations, teaching, or creative work with apps like OpenBoard.

---

## Features

- 🖥 Real-time screen streaming from Mac to tablet  
- ✏️ Smooth and fast drawing using touch or mouse  
- 🖱 Supports clicks, dragging, and multi-stroke drawing  
- 🔌 Works via USB (ADB) or wirelessly over LAN  
- 📱 Cross-platform Flutter client for Android tablets  

---

## Requirements

- Mac with Python 3.13+  
- Android tablet with Flutter installed (or APK)  
- Python packages: `websockets`, `mss`, `Pillow`, `pyobjc`  
- USB cable (for ADB option) or same Wi-Fi network (for wireless option)  

---

## Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/AirBoard.git
cd AirBoard

```

Mac
```bash
python3 -m venv venv
source venv/bin/activate

```

Windows (PowerShell):
```bash
.\venv\Scripts\Activate.ps1

```

Windows (cmd):
```bash
.\venv\Scripts\activate.bat

```


Install requirements
```bash
pip3 install -r requirements.txt  --break-system-packages

```

## Options to Start the Project

quick start
```bash
bash start.sh

```

#### 1️⃣ USB / ADB Mode (Recommended for Low Latency)
	
	1.	Connect your tablet to the Mac via USB.
	2.	Reverse the ports with ADB:

```bash
adb reverse tcp:9001 tcp:9001
adb reverse tcp:9002 tcp:9002

```

    3.	Start the Python server:

    verify main on main.py should be

```bash
async def main():
    print("Run this server and then open the browser on tablet with the correct IP.")
    async with websockets.serve(stream_screen, "localhost", 9001), \
               websockets.serve(handle_input, "localhost", 9002):
        await asyncio.Future()  # run forever

```

```bash
python3 main.py

```

	4.	Open the Flutter app on your tablet (or install APK).
	5.	The app connects automatically to ws://localhost:9001 and ws://localhost:9002.

    This mode ensures minimal latency and stable connection without Wi-Fi dependency.

---

#### 2️⃣ Wireless Mode

	1.	Make sure your Mac and tablet are on the same Wi-Fi network.
	2.	Replace localhost with your Mac’s LAN IP in Flutter client:

```bash
final screenUrl = "ws://192.168.x.x:9001";
final inputUrl  = "ws://192.168.x.x:9002";

```

	3.	Start the Python server:

    verify main on main.py should be

```bash
async def main():
    print("Run this server and then open the browser on tablet with the correct IP.")
    async with websockets.serve(stream_screen, "192.168.x.x", 9001), \
               websockets.serve(handle_input, "192.168.x.x", 9002):
        await asyncio.Future()  # run forever

```

```bash
python3 main.py

```

	4.	Launch the Flutter app on your tablet.

    Wireless mode is convenient but may have slightly higher latency depending on network speed.

### Usage

	•	Draw / swipe on the tablet screen → reflected on the Mac in real-time.
	•	Tap to click.
	•	Supports multi-stroke drawing with accurate scaling.

### Troubleshooting

######	•	Cannot connect in release build (ADB mode)
	•	Make sure adb reverse is set before launching the app.
	•	Ensure android:usesCleartextTraffic="true" and network_security_config.xml are configured.
######	•	Wireless connection not working
	•	Confirm both devices are on the same LAN.
	•	Replace localhost with Mac’s IP.
	•	Check firewall allows Python to accept incoming connections.
######	•	Preview too blurry
	•	Increase STREAM_WIDTH and JPEG_QUALITY in main.py.
	•	Set filterQuality: FilterQuality.high in Flutter Image.memory.

### License

MIT License – free to use and modify.

```bash
License

MIT License – free to use and modify.

```