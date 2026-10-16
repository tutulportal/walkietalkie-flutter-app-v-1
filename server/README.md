# Walkie-Talkie Relay Server

This folder contains two implementations of the Walkie-Talkie Audio Relay Server:
1. **Pure Dart Server** (`bin/server.dart`) — Zero external dependencies, runs directly with Flutter/Dart.
2. **Node.js Server** (`server.js`) — High-performance WebSocket server with `ws`.

Both servers are 100% wire-compatible and provide:
- **Server Code / Frequency Room isolation** (`roomCode`): Only radios set to the same Room Code & Channel will hear each other.
- **Half-Duplex Radio Emulation**: When one user presses PTT, the channel is locked, preventing overlapping collisions just like real RF transceivers.
- **Low-Latency Binary Audio Streaming**: Microphone audio chunks are routed in real-time.
- **Roger Beeps & Squelch Tail Events**: Synchronized sound triggers across all listener devices.
- **Call Alert Tone**: Dispatches 1750 Hz calling chime to all radios on the frequency.

---

## Option 1: Running the Dart Server (Easiest, zero install)
No npm or node needed, just run:
```bash
dart run server/bin/server.dart
```

---

## Option 2: Running the Node.js Server
```bash
cd server
npm install
node server.js
```

---

## How to Connect Your Walkie-Talkie App

1. **Local WiFi Testing (Multiple Phones/Computers)**:
   - Find your computer's local IP address (e.g., `192.168.1.15`). On Windows run `ipconfig`.
   - In the Walkie-Talkie Flutter app, tap the **CONFIG** button on the radio.
   - Enter Server URL: `ws://192.168.1.15:8080` (or `ws://10.0.2.2:8080` if testing in Android Emulator).
   - Enter Room Code: `ALPHA` (or whatever channel code your group wants to use, e.g. `TEAM-1`).
   - Pick the same Channel (e.g. `CH-01`).
   - Press and hold the big **PTT** button to speak!

2. **Free Cloud Deployment (Talk from anywhere in the world)**:
   - You can deploy either server to free hosting platforms like:
     - **Render.com** (Web Service, Docker or Node)
     - **Railway.app**
     - **Fly.io**
   - Once deployed, your server URL will look like: `wss://my-walkie-talkie.onrender.com`
   - Share this URL and your group's Room Code with your friends!
