/**
 * Walkie-Talkie WebSocket Relay Server (Node.js)
 * 
 * Features:
 * - Room / Server Code isolation: only radios with the same serverCode & channel hear each other
 * - Binary & JSON message multiplexing (ultra-low latency audio streaming)
 * - Half-Duplex Radio Lock: When a user holds PTT ("TX"), others receive "BUSY" status
 * - PTT release triggers roger beep & squelch tail notification to listeners
 * - Live user presence & call sign tracking
 * 
 * To run:
 *   node server.js
 * Default Port: 8080 (or process.env.PORT)
 */

const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8080;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    name: 'Walkie-Talkie Audio Server',
    status: 'ONLINE',
    time: new Date().toISOString(),
    connectedClients: wss.clients.size
  }));
});

const wss = new WebSocket.Server({ server });

// State storage:
// channels[roomCode + ':' + channelNumber] = { currentSpeakerId, currentSpeakerCallsign }
const channelStates = new Map();

function getChannelKey(roomCode, channel) {
  return `${(roomCode || 'DEFAULT').toUpperCase().trim()}:${channel || 1}`;
}

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  ws.id = 'radio_' + Math.random().toString(36).substring(2, 9);
  ws.roomCode = 'ALPHA';
  ws.channel = 1;
  ws.callSign = 'RADIO-' + ws.id.substring(6).toUpperCase();
  ws.isTransmitting = false;
  ws.isAlive = true;

  console.log(`[+] Radio connected: ${ws.id} (${clientIp})`);

  ws.on('pong', () => {
    ws.isAlive = true;
  });

  ws.on('message', (data, isBinary) => {
    if (isBinary) {
      // Audio packet forwarding:
      // Binary packet layout:
      // Header: 4 bytes (Channel byte, Room length byte, Room string, Audio payload)
      // Or if raw audio from active speaker, forward to everyone in the same room & channel!
      if (!ws.isTransmitting) return;

      const key = getChannelKey(ws.roomCode, ws.channel);
      const state = channelStates.get(key);
      if (state && state.currentSpeakerId === ws.id) {
        // Forward binary audio directly to all peers on same room & channel
        wss.clients.forEach(client => {
          if (client !== ws && client.readyState === WebSocket.OPEN) {
            if (getChannelKey(client.roomCode, client.channel) === key) {
              client.send(data, { binary: true });
            }
          }
        });
      }
      return;
    }

    try {
      const msg = JSON.parse(data.toString());

      switch (msg.type) {
        case 'JOIN': {
          ws.roomCode = (msg.roomCode || 'ALPHA').toUpperCase().trim();
          ws.channel = msg.channel || 1;
          ws.callSign = msg.callSign || ws.callSign;

          console.log(`[JOIN] ${ws.callSign} (${ws.id}) -> Room: ${ws.roomCode}, Channel: ${ws.channel}`);

          ws.send(JSON.stringify({
            type: 'JOINED',
            id: ws.id,
            roomCode: ws.roomCode,
            channel: ws.channel,
            callSign: ws.callSign,
            serverTime: Date.now()
          }));

          broadcastChannelUsers(ws.roomCode, ws.channel);
          break;
        }

        case 'SET_CHANNEL': {
          const oldKey = getChannelKey(ws.roomCode, ws.channel);
          // If was transmitting, release lock
          if (ws.isTransmitting) {
            handlePttRelease(ws);
          }

          ws.channel = msg.channel || 1;
          console.log(`[CHANNEL] ${ws.callSign} switched to CH-${ws.channel}`);

          ws.send(JSON.stringify({
            type: 'CHANNEL_UPDATED',
            channel: ws.channel
          }));

          broadcastChannelUsers(ws.roomCode, ws.channel);
          break;
        }

        case 'PTT_START': {
          const key = getChannelKey(ws.roomCode, ws.channel);
          let state = channelStates.get(key);

          if (state && state.currentSpeakerId && state.currentSpeakerId !== ws.id) {
            // Channel is already busy! Real walkie talkies reject or signal BUSY
            ws.send(JSON.stringify({
              type: 'TX_DENIED',
              reason: 'CHANNEL_BUSY',
              busyBy: state.currentSpeakerCallsign
            }));
            return;
          }

          // Acquire channel lock
          channelStates.set(key, {
            currentSpeakerId: ws.id,
            currentSpeakerCallsign: ws.callSign,
            startedAt: Date.now()
          });
          ws.isTransmitting = true;

          console.log(`[PTT_START] ${ws.callSign} transmitting on ${key}`);

          // Notify all clients on this channel that this radio is transmitting
          wss.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN && getChannelKey(client.roomCode, client.channel) === key) {
              client.send(JSON.stringify({
                type: 'RX_START',
                speakerId: ws.id,
                callSign: ws.callSign,
                rogerBeep: msg.rogerBeep || 'STANDARD'
              }));
            }
          });
          break;
        }

        case 'PTT_END': {
          handlePttRelease(ws, msg.rogerBeep);
          break;
        }

        case 'CALL_ALERT': {
          // Send 1750 Hz / 2-tone radio alert to everyone on channel
          const key = getChannelKey(ws.roomCode, ws.channel);
          console.log(`[CALL_ALERT] from ${ws.callSign} on ${key}`);
          wss.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN && getChannelKey(client.roomCode, client.channel) === key) {
              client.send(JSON.stringify({
                type: 'CALL_ALERT',
                fromCallSign: ws.callSign,
                channel: ws.channel
              }));
            }
          });
          break;
        }

        case 'PING': {
          ws.send(JSON.stringify({ type: 'PONG', timestamp: Date.now() }));
          break;
        }
      }
    } catch (err) {
      console.error('[!] Error parsing message:', err.message);
    }
  });

  ws.on('close', () => {
    console.log(`[-] Radio disconnected: ${ws.callSign} (${ws.id})`);
    if (ws.isTransmitting) {
      handlePttRelease(ws);
    }
    broadcastChannelUsers(ws.roomCode, ws.channel);
  });
});

function handlePttRelease(ws, rogerBeepStyle = 'STANDARD') {
  const key = getChannelKey(ws.roomCode, ws.channel);
  const state = channelStates.get(key);

  if (state && state.currentSpeakerId === ws.id) {
    channelStates.delete(key);
    ws.isTransmitting = false;

    console.log(`[PTT_END] ${ws.callSign} released on ${key}`);

    // Notify listeners to close RX and trigger roger beep / squelch tail
    wss.clients.forEach(client => {
      if (client.readyState === WebSocket.OPEN && getChannelKey(client.roomCode, client.channel) === key) {
        client.send(JSON.stringify({
          type: 'RX_END',
          speakerId: ws.id,
          callSign: ws.callSign,
          rogerBeep: rogerBeepStyle
        }));
      }
    });
  }
}

function broadcastChannelUsers(roomCode, channel) {
  const key = getChannelKey(roomCode, channel);
  const users = [];

  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN && getChannelKey(client.roomCode, client.channel) === key) {
      users.push({
        id: client.id,
        callSign: client.callSign
      });
    }
  });

  const payload = JSON.stringify({
    type: 'USERS_UPDATE',
    roomCode,
    channel,
    count: users.length,
    users
  });

  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN && getChannelKey(client.roomCode, client.channel) === key) {
      client.send(payload);
    }
  });
}

// Heartbeat ping interval
const interval = setInterval(() => {
  wss.clients.forEach(ws => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on('close', () => clearInterval(interval));

server.listen(PORT, '0.0.0.0', () => {
  console.log('==================================================');
  console.log(`📡 WALKIE-TALKIE SERVER RUNNING ON PORT ${PORT}`);
  console.log(`🔗 Local Address:  ws://localhost:${PORT}`);
  console.log(`👥 WebSocket ready for live audio streaming`);
  console.log('==================================================');
});
