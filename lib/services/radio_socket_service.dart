import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/radio_state.dart';

/// Handles WebSocket network communication between the Walkie-Talkie app
/// and the custom Walkie-Talkie Relay Server.
class RadioSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  ConnectionStateEnum _state = ConnectionStateEnum.disconnected;
  ConnectionStateEnum get state => _state;

  final _stateController = StreamController<ConnectionStateEnum>.broadcast();
  Stream<ConnectionStateEnum> get connectionStateStream => _stateController.stream;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  final _audioController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get audioStream => _audioController.stream;

  String _currentServerUrl = '';
  String _currentRoomCode = 'ALPHA';
  int _currentChannel = 1;
  String _currentCallSign = 'VIPER-01';

  String get roomCode => _currentRoomCode;
  int get currentChannel => _currentChannel;
  String get callSign => _currentCallSign;

  void _setState(ConnectionStateEnum newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  Future<void> connect({
    required String serverUrl,
    required String roomCode,
    required int channel,
    required String callSign,
  }) async {
    _currentServerUrl = serverUrl.trim();
    _currentRoomCode = roomCode.trim().toUpperCase();
    _currentChannel = channel;
    _currentCallSign = callSign.trim();

    await disconnect();

    _setState(ConnectionStateEnum.connecting);

    try {
      final uri = Uri.parse(_currentServerUrl);
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (data) {
          if (data is List<int>) {
            // Incoming binary audio data from active transmitter
            _audioController.add(Uint8List.fromList(data));
          } else {
            // Incoming JSON control message
            try {
              final msg = jsonDecode(data.toString()) as Map<String, dynamic>;
              _handleServerMessage(msg);
            } catch (e) {
              // ignore parse errors
            }
          }
        },
        onDone: () {
          _setState(ConnectionStateEnum.disconnected);
          _pingTimer?.cancel();
        },
        onError: (error) {
          _setState(ConnectionStateEnum.error);
          _pingTimer?.cancel();
        },
      );

      // Send initial JOIN packet
      _sendJson({
        'type': 'JOIN',
        'roomCode': _currentRoomCode,
        'channel': _currentChannel,
        'callSign': _currentCallSign,
      });

      _startPingHeartbeat();
      _setState(ConnectionStateEnum.connected);
    } catch (e) {
      _setState(ConnectionStateEnum.error);
    }
  }

  void _handleServerMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == 'PONG') return;

    if (type == 'JOINED') {
      _setState(ConnectionStateEnum.connected);
    }

    _eventController.add(msg);
  }

  void setChannel(int newChannel) {
    _currentChannel = newChannel;
    if (_state == ConnectionStateEnum.connected) {
      _sendJson({
        'type': 'SET_CHANNEL',
        'channel': newChannel,
      });
    }
  }

  void updateConfig({required String roomCode, required String callSign}) {
    _currentRoomCode = roomCode.trim().toUpperCase();
    _currentCallSign = callSign.trim();
    if (_state == ConnectionStateEnum.connected) {
      _sendJson({
        'type': 'JOIN',
        'roomCode': _currentRoomCode,
        'channel': _currentChannel,
        'callSign': _currentCallSign,
      });
    }
  }

  void sendPttStart({required String rogerBeep}) {
    if (_state == ConnectionStateEnum.connected) {
      _sendJson({
        'type': 'PTT_START',
        'rogerBeep': rogerBeep,
      });
    }
  }

  void sendAudioChunk(Uint8List bytes) {
    if (_state == ConnectionStateEnum.connected && _channel != null) {
      try {
        _channel!.sink.add(bytes);
      } catch (e) {
        // Handle socket sink error silently
      }
    }
  }

  void sendPttEnd({required String rogerBeep}) {
    if (_state == ConnectionStateEnum.connected) {
      _sendJson({
        'type': 'PTT_END',
        'rogerBeep': rogerBeep,
      });
    }
  }

  void sendCallAlert() {
    if (_state == ConnectionStateEnum.connected) {
      _sendJson({
        'type': 'CALL_ALERT',
      });
    }
  }

  void _sendJson(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      // ignore
    }
  }

  void _startPingHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_state == ConnectionStateEnum.connected) {
        _sendJson({'type': 'PING'});
      }
    });
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(ConnectionStateEnum.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _eventController.close();
    _audioController.close();
  }
}
