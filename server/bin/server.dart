import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Standalone Walkie-Talkie WebSocket Server (Pure Dart)
/// Runs out of the box with zero third-party dependencies:
///   dart run server/bin/server.dart
void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  print('====================================================');
  print('📡 WALKIE-TALKIE DART SERVER LISTENING ON PORT $port');
  print('🔗 Local IP address: ws://localhost:$port');
  print('📱 Connect your Walkie-Talkie app to this address');
  print('====================================================');

  final clients = <ClientConnection>[];
  final channelLocks = <String, ClientConnection>{};

  String getChannelKey(String roomCode, int channel) =>
      '${roomCode.toUpperCase().trim()}:$channel';

  void broadcastToChannel(
      String key, dynamic message, {ClientConnection? exclude}) {
    for (final client in clients) {
      if (client != exclude &&
          getChannelKey(client.roomCode, client.channel) == key &&
          client.socket.readyState == WebSocket.open) {
        if (message is List<int>) {
          client.socket.add(message);
        } else {
          client.socket.add(message.toString());
        }
      }
    }
  }

  void broadcastUserList(String roomCode, int channel) {
    final key = getChannelKey(roomCode, channel);
    final usersOnChannel = clients
        .where((c) =>
            getChannelKey(c.roomCode, c.channel) == key &&
            c.socket.readyState == WebSocket.open)
        .map((c) => {'id': c.id, 'callSign': c.callSign})
        .toList();

    final payload = jsonEncode({
      'type': 'USERS_UPDATE',
      'roomCode': roomCode,
      'channel': channel,
      'count': usersOnChannel.length,
      'users': usersOnChannel,
    });

    for (final client in clients) {
      if (getChannelKey(client.roomCode, client.channel) == key &&
          client.socket.readyState == WebSocket.open) {
        client.socket.add(payload);
      }
    }
  }

  void releaseLock(ClientConnection client, {String rogerBeep = 'STANDARD'}) {
    final key = getChannelKey(client.roomCode, client.channel);
    if (channelLocks[key] == client) {
      channelLocks.remove(key);
      client.isTransmitting = false;
      print('[PTT_END] ${client.callSign} released on $key');

      broadcastToChannel(
        key,
        jsonEncode({
          'type': 'RX_END',
          'speakerId': client.id,
          'callSign': client.callSign,
          'rogerBeep': rogerBeep,
        }),
      );
    }
  }

  await for (HttpRequest request in server) {
    if (request.uri.path == '/') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        final randomId =
            'rad_${Random().nextInt(999999).toString().padLeft(6, '0')}';
        final conn = ClientConnection(
          id: randomId,
          socket: socket,
          roomCode: 'ALPHA',
          channel: 1,
          callSign: 'RADIO-${randomId.substring(4)}',
        );
        clients.add(conn);
        print('[+] Radio connected: ${conn.id}');

        socket.listen(
          (dynamic data) {
            if (data is List<int>) {
              // Binary Audio Frame
              if (!conn.isTransmitting) return;
              final key = getChannelKey(conn.roomCode, conn.channel);
              if (channelLocks[key] == conn) {
                broadcastToChannel(key, data, exclude: conn);
              }
              return;
            }

            try {
              final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
              final type = msg['type'] as String?;

              switch (type) {
                case 'JOIN':
                  conn.roomCode =
                      (msg['roomCode'] as String? ?? 'ALPHA').toUpperCase();
                  conn.channel = (msg['channel'] as num? ?? 1).toInt();
                  if (msg['callSign'] != null) {
                    conn.callSign = msg['callSign'].toString();
                  }

                  conn.socket.add(jsonEncode({
                    'type': 'JOINED',
                    'id': conn.id,
                    'roomCode': conn.roomCode,
                    'channel': conn.channel,
                    'callSign': conn.callSign,
                  }));

                  broadcastUserList(conn.roomCode, conn.channel);
                  break;

                case 'SET_CHANNEL':
                  if (conn.isTransmitting) {
                    releaseLock(conn);
                  }
                  final oldChannel = conn.channel;
                  final oldRoom = conn.roomCode;
                  conn.channel = (msg['channel'] as num? ?? 1).toInt();

                  conn.socket.add(jsonEncode({
                    'type': 'CHANNEL_UPDATED',
                    'channel': conn.channel,
                  }));

                  broadcastUserList(oldRoom, oldChannel);
                  broadcastUserList(conn.roomCode, conn.channel);
                  break;

                case 'PTT_START':
                  final key = getChannelKey(conn.roomCode, conn.channel);
                  final currentSpeaker = channelLocks[key];

                  if (currentSpeaker != null && currentSpeaker != conn) {
                    // Channel busy!
                    conn.socket.add(jsonEncode({
                      'type': 'TX_DENIED',
                      'reason': 'CHANNEL_BUSY',
                      'busyBy': currentSpeaker.callSign,
                    }));
                    return;
                  }

                  channelLocks[key] = conn;
                  conn.isTransmitting = true;
                  print('[PTT_START] ${conn.callSign} keyed mic on $key');

                  broadcastToChannel(
                    key,
                    jsonEncode({
                      'type': 'RX_START',
                      'speakerId': conn.id,
                      'callSign': conn.callSign,
                      'rogerBeep': msg['rogerBeep'] ?? 'STANDARD',
                    }),
                  );
                  break;

                case 'PTT_END':
                  releaseLock(conn,
                      rogerBeep: msg['rogerBeep']?.toString() ?? 'STANDARD');
                  break;

                case 'CALL_ALERT':
                  final key = getChannelKey(conn.roomCode, conn.channel);
                  broadcastToChannel(
                    key,
                    jsonEncode({
                      'type': 'CALL_ALERT',
                      'fromCallSign': conn.callSign,
                      'channel': conn.channel,
                    }),
                  );
                  break;

                case 'PING':
                  conn.socket.add(jsonEncode({'type': 'PONG'}));
                  break;
              }
            } catch (e) {
              print('[!] Error parsing JSON: $e');
            }
          },
          onDone: () {
            print('[-] Radio disconnected: ${conn.callSign} (${conn.id})');
            releaseLock(conn);
            clients.remove(conn);
            broadcastUserList(conn.roomCode, conn.channel);
          },
          onError: (e) {
            print('[!] Socket error for ${conn.id}: $e');
            releaseLock(conn);
            clients.remove(conn);
            broadcastUserList(conn.roomCode, conn.channel);
          },
        );
      } else {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'status': 'ONLINE',
            'server': 'Walkie-Talkie Dart Server',
            'clients': clients.length,
          }))
          ..close();
      }
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }
}

class ClientConnection {
  final String id;
  final WebSocket socket;
  String roomCode;
  int channel;
  String callSign;
  bool isTransmitting = false;

  ClientConnection({
    required this.id,
    required this.socket,
    required this.roomCode,
    required this.channel,
    required this.callSign,
  });
}
