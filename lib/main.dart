import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/radio_channel.dart';
import 'models/radio_state.dart';
import 'services/audio_manager.dart';
import 'services/radio_socket_service.dart';
import 'widgets/about_creator_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/startup_permission_dialog.dart';
import 'widgets/walkie_talkie_chassis.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const WalkieTalkieApp());
}

class WalkieTalkieApp extends StatelessWidget {
  const WalkieTalkieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walkie-Talkie Transceiver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0E11),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9E1B),
          secondary: Color(0xFF00FF66),
          surface: Color(0xFF161A20),
        ),
      ),
      home: const WalkieTalkieScreen(),
    );
  }
}

class WalkieTalkieScreen extends StatefulWidget {
  const WalkieTalkieScreen({super.key});

  @override
  State<WalkieTalkieScreen> createState() => _WalkieTalkieScreenState();
}

class _WalkieTalkieScreenState extends State<WalkieTalkieScreen> {
  final AudioManager _audioManager = AudioManager();
  final RadioSocketService _socketService = RadioSocketService();

  RadioConfig _config = RadioConfig();
  int _currentChannelIndex = 0; // 0 to 15 (CH-01 to CH-16)
  RadioTransmissionState _transmissionState = RadioTransmissionState.idle;
  ConnectionStateEnum _connectionState = ConnectionStateEnum.disconnected;

  String? _activeSpeakerCallsign;
  int _onlineUsersCount = 1;
  double _volume = 0.85;
  bool _isMonitorActive = false;
  bool _isScanning = false;
  Timer? _scanTimer;

  StreamSubscription? _eventSub;
  StreamSubscription? _statusSub;

  RadioChannel get _currentChannel =>
      RadioChannel.defaultChannels[_currentChannelIndex];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize audio synthesis engine
    await _audioManager.initialize();

    // 2. Load preferences
    await _loadConfig();

    // 3. Setup WebSocket listeners
    _setupSocketListeners();

    // 4. Connect to server
    _connectToServer();

    // 5. Trigger startup permissions dialog if required
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        StartupPermissionDialog.checkAndShow(context);
      }
    });
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    final serverUrl = (savedUrl == null || savedUrl == 'ws://localhost:8080' || savedUrl == 'ws://10.0.2.2:8080')
        ? 'wss://walkietalkie-flutter-app-v-1.onrender.com'
        : savedUrl;

    setState(() {
      _config = RadioConfig(
        serverUrl: serverUrl,
        roomCode: prefs.getString('room_code') ?? 'ALPHA',
        callSign: prefs.getString('call_sign') ?? 'VIPER-01',
        rogerBeepStyle: prefs.getString('roger_beep') ?? 'STANDARD',
        lcdColorMode: prefs.getString('lcd_color') ?? 'AMBER',
        squelchLevel: prefs.getInt('squelch_level') ?? 3,
        volume: prefs.getDouble('volume') ?? 0.85,
      );
      _volume = _config.volume;
      _currentChannelIndex = (prefs.getInt('current_channel') ?? 1) - 1;
      if (_currentChannelIndex < 0 || _currentChannelIndex > 15) {
        _currentChannelIndex = 0;
      }
    });
    _audioManager.setVolume(_volume);
  }

  Future<void> _saveConfig(RadioConfig updatedConfig) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', updatedConfig.serverUrl);
    await prefs.setString('room_code', updatedConfig.roomCode);
    await prefs.setString('call_sign', updatedConfig.callSign);
    await prefs.setString('roger_beep', updatedConfig.rogerBeepStyle);
    await prefs.setString('lcd_color', updatedConfig.lcdColorMode);
    await prefs.setInt('squelch_level', updatedConfig.squelchLevel);
    await prefs.setInt('current_channel', _currentChannelIndex + 1);

    setState(() {
      _config = updatedConfig;
    });

    // Reconnect or update room code
    _connectToServer();
  }

  void _setupSocketListeners() {
    _statusSub = _socketService.connectionStateStream.listen((status) {
      if (mounted) {
        setState(() => _connectionState = status);
      }
    });

    _eventSub = _socketService.eventStream.listen((event) async {
      final type = event['type'] as String?;

      switch (type) {
        case 'JOINED':
          if (mounted) {
            setState(() => _connectionState = ConnectionStateEnum.connected);
          }
          break;

        case 'USERS_UPDATE':
          if (mounted) {
            setState(() {
              _onlineUsersCount = (event['count'] as num?)?.toInt() ?? 1;
            });
          }
          break;

        case 'RX_START':
          final speaker = event['callSign']?.toString() ?? 'RADIO';
          if (mounted) {
            setState(() {
              _transmissionState = RadioTransmissionState.receiving;
              _activeSpeakerCallsign = speaker;
            });
          }
          await _audioManager.onIncomingRxStart();
          break;

        case 'RX_END':
          final style = event['rogerBeep']?.toString() ?? _config.rogerBeepStyle;
          if (mounted) {
            setState(() {
              _transmissionState = RadioTransmissionState.idle;
              _activeSpeakerCallsign = null;
            });
          }
          await _audioManager.onIncomingRxEnd(rogerBeepStyle: style);
          break;

        case 'TX_DENIED':
          final busyBy = event['busyBy']?.toString() ?? 'BUSY';
          if (mounted) {
            setState(() {
              _transmissionState = RadioTransmissionState.busy;
              _activeSpeakerCallsign = busyBy;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade900,
                content: Text(
                  'CHANNEL BUSY: $busyBy is currently transmitting!',
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _transmissionState == RadioTransmissionState.busy) {
              setState(() => _transmissionState = RadioTransmissionState.idle);
            }
          });
          break;

        case 'CALL_ALERT':
          final from = event['fromCallSign']?.toString() ?? 'RADIO';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.amber.shade900,
                content: Text(
                  '🚨 CALL ALERT RECEIVED FROM: $from',
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          await _audioManager.playCallAlert();
          break;
      }
    });

    _socketService.audioStream.listen((chunk) {
      _audioManager.onIncomingAudioChunk(chunk);
    });
  }

  void _connectToServer() {
    _socketService.connect(
      serverUrl: _config.serverUrl,
      roomCode: _config.roomCode,
      channel: _currentChannel.number,
      callSign: _config.callSign,
    );
  }

  // --- Controls Handlers ---

  void _onVolumeChanged(double val) {
    setState(() => _volume = val);
    _audioManager.setVolume(val);
  }

  void _onVolumeStep() {
    _audioManager.playKnobClick();
  }

  void _onChannelSelected(int channelNum) {
    final index = (channelNum - 1).clamp(0, 15);
    if (index != _currentChannelIndex) {
      setState(() => _currentChannelIndex = index);
      _audioManager.playKnobClick();
      _socketService.setChannel(_currentChannel.number);
    }
  }

  void _onChannelUp() {
    setState(() {
      _currentChannelIndex = (_currentChannelIndex + 1) % 16;
    });
    _audioManager.playKnobClick();
    _socketService.setChannel(_currentChannel.number);
  }

  void _onChannelDown() {
    setState(() {
      _currentChannelIndex = (_currentChannelIndex - 1 + 16) % 16;
    });
    _audioManager.playKnobClick();
    _socketService.setChannel(_currentChannel.number);
  }

  Future<void> _onPttDown() async {
    if (_transmissionState == RadioTransmissionState.receiving ||
        _transmissionState == RadioTransmissionState.busy) {
      return;
    }

    setState(() => _transmissionState = RadioTransmissionState.transmitting);
    _socketService.sendPttStart(rogerBeep: _config.rogerBeepStyle);

    final ok = await _audioManager.startTransmitting(
      onAudioChunk: (chunk) {
        _socketService.sendAudioChunk(chunk);
      },
    );

    if (!ok && mounted) {
      setState(() => _transmissionState = RadioTransmissionState.idle);
      _socketService.sendPttEnd(rogerBeep: _config.rogerBeepStyle);
    }
  }

  Future<void> _onPttUp() async {
    if (_transmissionState != RadioTransmissionState.transmitting) return;

    setState(() => _transmissionState = RadioTransmissionState.idle);
    await _audioManager.stopTransmitting(rogerBeepStyle: _config.rogerBeepStyle);
    _socketService.sendPttEnd(rogerBeep: _config.rogerBeepStyle);
  }

  void _onMonitorToggle() {
    setState(() => _isMonitorActive = !_isMonitorActive);
    _audioManager.toggleMonitor();
  }

  void _onCallAlert() {
    _audioManager.playCallAlert();
    _socketService.sendCallAlert();
  }

  void _onScanToggle() {
    setState(() => _isScanning = !_isScanning);
    _scanTimer?.cancel();

    if (_isScanning) {
      _scanTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        if (!mounted || !_isScanning) return;
        _onChannelUp();
      });
    }
  }

  void _onOpenConfig() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(
        config: _config,
        audioManager: _audioManager,
        onSave: (updated) => _saveConfig(updated),
      ),
    );
  }

  void _onOpenAboutCreator() {
    showDialog(
      context: context,
      builder: (ctx) => const AboutCreatorDialog(),
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _eventSub?.cancel();
    _statusSub?.cancel();
    _socketService.dispose();
    _audioManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14171C),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9E1B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.radio, color: Color(0xFFFF9E1B), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TACTICAL WALKIE-TALKIE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'SERVER: ${_config.serverUrl} [${_config.roomCode}]',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9.5,
                    color: Color(0xFF90A4AE),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Connection status badge
          Container(
            margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _connectionState == ConnectionStateEnum.connected
                  ? const Color(0xFF00FF66).withOpacity(0.15)
                  : (_connectionState == ConnectionStateEnum.connecting
                      ? Colors.amber.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _connectionState == ConnectionStateEnum.connected
                    ? const Color(0xFF00FF66)
                    : (_connectionState == ConnectionStateEnum.connecting
                        ? Colors.amber
                        : Colors.redAccent),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connectionState == ConnectionStateEnum.connected
                        ? const Color(0xFF00FF66)
                        : (_connectionState == ConnectionStateEnum.connecting
                            ? Colors.amber
                            : Colors.redAccent),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _connectionState == ConnectionStateEnum.connected
                      ? 'ONLINE'
                      : (_connectionState == ConnectionStateEnum.connecting
                          ? 'CONNECTING'
                          : 'DISCONNECTED'),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _connectionState == ConnectionStateEnum.connected
                        ? const Color(0xFF00FF66)
                        : (_connectionState == ConnectionStateEnum.connecting
                            ? Colors.amber
                            : Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF00FF66)),
            tooltip: 'System Creator & Specs (Tutul)',
            onPressed: _onOpenAboutCreator,
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFFF9E1B)),
            tooltip: 'Configure Radio & Server',
            onPressed: _onOpenConfig,
          ),
        ],
      ),
      body: SafeArea(
        child: WalkieTalkieChassis(
          currentChannel: _currentChannel,
          transmissionState: _transmissionState,
          connectionState: _connectionState,
          config: _config,
          activeSpeakerCallsign: _activeSpeakerCallsign,
          onlineUsersCount: _onlineUsersCount,
          volume: _volume,
          isMonitorActive: _isMonitorActive,
          isScanning: _isScanning,
          onVolumeChanged: _onVolumeChanged,
          onVolumeStep: _onVolumeStep,
          onChannelSelected: _onChannelSelected,
          onChannelUp: _onChannelUp,
          onChannelDown: _onChannelDown,
          onPttDown: _onPttDown,
          onPttUp: _onPttUp,
          onMonitorToggle: _onMonitorToggle,
          onCallAlert: _onCallAlert,
          onScanToggle: _onScanToggle,
          onOpenConfig: _onOpenConfig,
        ),
      ),
    );
  }
}
