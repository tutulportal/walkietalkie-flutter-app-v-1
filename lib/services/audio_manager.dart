import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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

  // Cached audio byte arrays for instant zero-latency playback across mobile and web
  Uint8List? _pttChirpBytes;
  Uint8List? _squelchTailBytes;
  Uint8List? _callAlertBytes;
  Uint8List? _knobClickBytes;
  Uint8List? _staticLoopBytes;
  final Map<String, Uint8List> _rogerBeepBytes = {};

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Synthesize sound effects into memory buffers
      _pttChirpBytes = SoundGenerator.createPttPressChirp();
      _squelchTailBytes = SoundGenerator.createSquelchTail();
      _callAlertBytes = SoundGenerator.createCallAlert();
      _knobClickBytes = SoundGenerator.createKnobClick();
      _staticLoopBytes = SoundGenerator.createRadioStaticLoop(durationSec: 2.0);

      final styles = [
        'STANDARD',
        'BAOFENG',
        'KENWOOD_DUAL',
        'NASA_QUINDAR',
        'MILITARY_TRIAD'
      ];
      for (final style in styles) {
        _rogerBeepBytes[style] = SoundGenerator.createRogerBeep(style);
      }

      await _sfxPlayer.setVolume(_volume);
      await _staticPlayer.setVolume(_volume * 0.35);
      await _voicePlayer.setVolume(1.0);

      // Configure global audio context for loud speakerphone and background playback
      try {
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.speech,
              usageType: AndroidUsageType.voiceCommunicationSignalling,
              audioMode: AndroidAudioMode.normal,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playAndRecord,
              options: const {
                AVAudioSessionOptions.defaultToSpeaker,
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('[AudioManager] AudioContext config note: $e');
      }

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
    if (_knobClickBytes == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(_knobClickBytes!), volume: _volume * 0.6);
    } catch (_) {}
  }

  Future<void> playPttChirp() async {
    if (_pttChirpBytes == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(_pttChirpBytes!), volume: _volume * 0.9);
    } catch (_) {}
  }

  Future<void> playRogerBeep(String style) async {
    if (style == 'OFF') return;
    final bytes = _rogerBeepBytes[style] ?? _rogerBeepBytes['STANDARD'];
    if (bytes == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(bytes), volume: _volume * 0.85);
    } catch (_) {}
  }

  Future<void> playSquelchTail() async {
    if (_squelchTailBytes == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(_squelchTailBytes!), volume: _volume);
    } catch (_) {}
  }

  Future<void> playCallAlert() async {
    if (_callAlertBytes == null) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(BytesSource(_callAlertBytes!), volume: _volume);
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
    if (_staticLoopBytes == null) return;
    try {
      await _staticPlayer.setReleaseMode(ReleaseMode.loop);
      await _staticPlayer.play(BytesSource(_staticLoopBytes!), volume: _volume * volumeRatio);
    } catch (_) {}
  }

  Future<void> stopStaticNoise() async {
    try {
      await _staticPlayer.stop();
    } catch (_) {}
  }

  /// Request microphone permission
  Future<bool> checkPermission() async {
    if (kIsWeb) {
      return await _recorder.hasPermission();
    }
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
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

  final BytesBuilder _incomingVoiceBuffer = BytesBuilder();

  /// Called when remote transmission begins
  Future<void> onIncomingRxStart() async {
    _incomingVoiceBuffer.clear();
    // Play subtle background radio static hiss behind incoming voice
    await startStaticNoise(volumeRatio: 0.15);
  }

  /// Feed incoming audio chunk to playback
  void onIncomingAudioChunk(Uint8List chunk) {
    if (chunk.isNotEmpty) {
      _incomingVoiceBuffer.add(chunk);
    }
  }

  /// Called when remote transmission ends
  Future<void> onIncomingRxEnd({String rogerBeepStyle = 'STANDARD'}) async {
    await stopStaticNoise();

    // Play accumulated voice audio if present
    final rawPcm = _incomingVoiceBuffer.takeBytes();
    if (rawPcm.length > 320) {
      try {
        final wavBytes = SoundGenerator.createWavFromPcm16(rawPcm, sampleRate: 16000);
        // Ensure maximum loud volume for background listening
        await _voicePlayer.setVolume(1.0);
        await _voicePlayer.play(BytesSource(wavBytes));

        // Wait for voice playback to finish (or max 12 seconds)
        await _voicePlayer.onPlayerComplete.first.timeout(
          const Duration(seconds: 12),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint('[AudioManager] voice playback error: $e');
      }
    }

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
