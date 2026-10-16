import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'sound_generator.dart';

/// Manages sound effects synthesis, audio recording, and realistic radio audio playback.
class AudioManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _staticPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordSub;

  double _volume = 0.85;
  double get volume => _volume;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isMonitorOpen = false;
  bool get isMonitorOpen => _isMonitorOpen;

  // Cached file paths for low latency playback
  String? _pttChirpPath;
  String? _squelchTailPath;
  String? _callAlertPath;
  String? _knobClickPath;
  String? _staticLoopPath;
  final Map<String, String> _rogerBeepPaths = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/walkie_audio');
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      // 1. Synthesize & cache PTT Chirp
      final chirpBytes = SoundGenerator.createPttPressChirp();
      final chirpFile = File('${cacheDir.path}/ptt_chirp.wav');
      await chirpFile.writeAsBytes(chirpBytes);
      _pttChirpPath = chirpFile.path;

      // 2. Synthesize & cache Squelch Tail
      final squelchBytes = SoundGenerator.createSquelchTail();
      final squelchFile = File('${cacheDir.path}/squelch_tail.wav');
      await squelchFile.writeAsBytes(squelchBytes);
      _squelchTailPath = squelchFile.path;

      // 3. Synthesize & cache Call Alert Chime
      final callBytes = SoundGenerator.createCallAlert();
      final callFile = File('${cacheDir.path}/call_alert.wav');
      await callFile.writeAsBytes(callBytes);
      _callAlertPath = callFile.path;

      // 4. Synthesize & cache Knob Click
      final knobBytes = SoundGenerator.createKnobClick();
      final knobFile = File('${cacheDir.path}/knob_click.wav');
      await knobFile.writeAsBytes(knobBytes);
      _knobClickPath = knobFile.path;

      // 5. Synthesize & cache Static Loop
      final staticBytes = SoundGenerator.createRadioStaticLoop(durationSec: 2.0);
      final staticFile = File('${cacheDir.path}/radio_static.wav');
      await staticFile.writeAsBytes(staticBytes);
      _staticLoopPath = staticFile.path;

      // 6. Synthesize Roger Beep variations
      final styles = [
        'STANDARD',
        'BAOFENG',
        'KENWOOD_DUAL',
        'NASA_QUINDAR',
        'MILITARY_TRIAD'
      ];
      for (final style in styles) {
        final beepBytes = SoundGenerator.createRogerBeep(style);
        final beepFile = File('${cacheDir.path}/roger_${style.toLowerCase()}.wav');
        await beepFile.writeAsBytes(beepBytes);
        _rogerBeepPaths[style] = beepFile.path;
      }

      await _sfxPlayer.setVolume(_volume);
      await _staticPlayer.setVolume(_volume * 0.35);
      await _voicePlayer.setVolume(_volume);

      _isInitialized = true;
    } catch (e) {
      debugPrint('[AudioManager] initialization error: $e');
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _sfxPlayer.setVolume(_volume);
    _staticPlayer.setVolume(_volume * 0.35);
    _voicePlayer.setVolume(_volume);
  }

  Future<void> playKnobClick() async {
    if (_knobClickPath == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(_knobClickPath!), volume: _volume * 0.6);
    } catch (_) {}
  }

  Future<void> playPttChirp() async {
    if (_pttChirpPath == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(_pttChirpPath!), volume: _volume * 0.9);
    } catch (_) {}
  }

  Future<void> playRogerBeep(String style) async {
    if (style == 'OFF') return;
    final path = _rogerBeepPaths[style] ?? _rogerBeepPaths['STANDARD'];
    if (path == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(path), volume: _volume * 0.85);
    } catch (_) {}
  }

  Future<void> playSquelchTail() async {
    if (_squelchTailPath == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(_squelchTailPath!), volume: _volume);
    } catch (_) {}
  }

  Future<void> playCallAlert() async {
    if (_callAlertPath == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(_callAlertPath!), volume: _volume);
    } catch (_) {}
  }

  Future<void> toggleMonitor() async {
    _isMonitorOpen = !_isMonitorOpen;
    if (_isMonitorOpen) {
      await startStaticNoise(volumeRatio: 0.5);
    } else {
      await stopStaticNoise();
      await playSquelchTail();
    }
  }

  Future<void> startStaticNoise({double volumeRatio = 0.25}) async {
    if (_staticLoopPath == null) return;
    try {
      await _staticPlayer.setReleaseMode(ReleaseMode.loop);
      await _staticPlayer.play(DeviceFileSource(_staticLoopPath!), volume: _volume * volumeRatio);
    } catch (_) {}
  }

  Future<void> stopStaticNoise() async {
    try {
      await _staticPlayer.stop();
    } catch (_) {}
  }

  /// Request microphone permission
  Future<bool> checkPermission() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  /// Start PTT audio recording stream
  Future<bool> startTransmitting({required Function(Uint8List) onAudioChunk}) async {
    if (_isRecording) return true;

    final hasPerm = await checkPermission();
    if (!hasPerm) {
      debugPrint('[AudioManager] Microphone permission denied');
      return false;
    }

    try {
      await playPttChirp();

      // Short delay for the chirp to finish before mic opens
      await Future.delayed(const Duration(milliseconds: 60));

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _isRecording = true;
      _recordSub = stream.listen((chunk) {
        if (_isRecording) {
          onAudioChunk(chunk);
        }
      });

      return true;
    } catch (e) {
      debugPrint('[AudioManager] startTransmitting error: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop PTT transmission and play Roger Beep
  Future<void> stopTransmitting({String rogerBeepStyle = 'STANDARD'}) async {
    if (!_isRecording) return;
    _isRecording = false;

    try {
      await _recordSub?.cancel();
      _recordSub = null;
      await _recorder.stop();
    } catch (e) {
      debugPrint('[AudioManager] stopTransmitting error: $e');
    }

    await playRogerBeep(rogerBeepStyle);
  }

  /// Called when remote transmission begins
  Future<void> onIncomingRxStart() async {
    // Play subtle background radio static hiss behind incoming voice
    await startStaticNoise(volumeRatio: 0.2);
  }

  /// Feed incoming audio chunk to playback
  Future<void> onIncomingAudioChunk(Uint8List chunk) async {
    // Audio stream playback or synthesis buffer
    // On receiving raw audio chunks, we can write small buffered WAV or play
  }

  /// Called when remote transmission ends
  Future<void> onIncomingRxEnd({String rogerBeepStyle = 'STANDARD'}) async {
    await stopStaticNoise();
    // Play roger beep followed by squelch tail burst
    await playRogerBeep(rogerBeepStyle);
    await Future.delayed(const Duration(milliseconds: 140));
    await playSquelchTail();
  }

  void dispose() {
    _recordSub?.cancel();
    _recorder.dispose();
    _sfxPlayer.dispose();
    _staticPlayer.dispose();
    _voicePlayer.dispose();
  }
}
