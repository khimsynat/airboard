import asyncio
import websockets
import json
import io
from mss import mss
from PIL import Image
import time

from Quartz.CoreGraphics import kCGEventLeftMouseDown, kCGEventLeftMouseUp, kCGEventLeftMouseDragged, CGEventCreate

from Quartz.CoreGraphics import CGEventCreateMouseEvent, CGEventPost, kCGHIDEventTap
import Quartz

# ---------------- CONFIG ----------------
# STREAM_WIDTH = 640
# JPEG_QUALITY = 50
STREAM_WIDTH = 960  # Increase width (was 640)
JPEG_QUALITY = 80 
FRAME_DELAY = 0.03  # ~33 FPS


mac_width, mac_height = 1440, 900  # placeholder, will get dynamically

# ---------------- QUARTZ INPUT ----------------
def mouse_down(x, y):
    evt = CGEventCreateMouseEvent(None, kCGEventLeftMouseDown, (x, y), 0)
    CGEventPost(kCGHIDEventTap, evt)

def mouse_move(x, y):
    evt = CGEventCreateMouseEvent(None, kCGEventLeftMouseDragged, (x, y), 0)
    CGEventPost(kCGHIDEventTap, evt)
    

def mouse_up(pos=None):
    # Get current cursor position
    loc = Quartz.CGEventGetLocation(Quartz.CGEventCreate(None))
    evt = CGEventCreateMouseEvent(None, kCGEventLeftMouseUp, loc, 0)
    CGEventPost(kCGHIDEventTap, evt)

def click(x, y):
    mouse_down(x, y)
    time.sleep(0.01)
    mouse_up(None)
    
    
# Global stroke flag
stroke_active = False
last_pos = None

async def handle_input(websocket):
    global last_pos, stroke_active
    print("Input client connected")
    async for message in websocket:
        try:
            cmd, coords = message.split(":")
            x, y = map(int, coords.split(","))

            if cmd == "down":
                last_pos = (x, y)
                stroke_active = True
                mouse_down(x, y)

            elif cmd == "move":
                if stroke_active and last_pos is not None:
                    mouse_move(x, y)
                last_pos = (x, y)

            elif cmd == "up":
                if stroke_active:
                    mouse_up()
                    stroke_active = False
                last_pos = None  # reset for next stroke

            elif cmd == "click":
                click(x, y)
                stroke_active = False
                last_pos = None

        except Exception as e:
            print("Input error:", e)

# ---------------- SCREEN STREAM ----------------
async def stream_screen(websocket):
    print("Screen client connected")
    with mss() as sct:
        monitor = sct.monitors[1]
        global mac_width, mac_height
        mac_width, mac_height = monitor["width"], monitor["height"]
        config = {"type": "config", "width": mac_width, "height": mac_height}
        await websocket.send(json.dumps(config))

        while True:
            try:
                img = sct.grab(monitor)
                pil = Image.frombytes("RGB", img.size, img.rgb)
                scale = STREAM_WIDTH / mac_width
                stream_height = int(mac_height * scale)
                pil_resized = pil.resize((STREAM_WIDTH, stream_height), Image.Resampling.LANCZOS)

                with io.BytesIO() as buf:
                    pil_resized.save(buf, format="JPEG", quality=JPEG_QUALITY)
                    await websocket.send(buf.getvalue())

                await asyncio.sleep(FRAME_DELAY)
            except websockets.exceptions.ConnectionClosed:
                print("Screen client disconnected")
                break
            except Exception as e:
                print("Screen error:", e)
                break

# ---------------- MAIN SERVER ----------------
async def main():
    print("Run this server and then open the browser on tablet with the correct IP.")
    # Using ADB
    async with websockets.serve(stream_screen, "localhost", 9001), \
               websockets.serve(handle_input, "localhost", 9002):
        await asyncio.Future()  # run forever
        
    # __________
    # Using Wireless Lan
    # async with websockets.serve(stream_screen, "0.0.0.0", 9001), \
    #            websockets.serve(handle_input, "0.0.0.0", 9002):
    #     await asyncio.Future()  # run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Server shutting down.")