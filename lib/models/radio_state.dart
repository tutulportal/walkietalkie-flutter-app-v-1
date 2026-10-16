enum ConnectionStateEnum {
  disconnected,
  connecting,
  connected,
  error,
}

enum RadioTransmissionState {
  idle,
  transmitting, // TX (user holding PTT)
  receiving,    // RX (someone speaking on channel)
  busy,         // Channel in use, cannot TX
}

class RadioConfig {
  String serverUrl;
  String roomCode;
  String callSign;
  String rogerBeepStyle;
  String lcdColorMode;
  int squelchLevel;
  double volume;
  bool isRadioFilterEnabled;
  bool hapticFeedback;

  RadioConfig({
    this.serverUrl = 'wss://walkietalkie-flutter-app-v-1.onrender.com',
    this.roomCode = 'ALPHA',
    this.callSign = 'VIPER-01',
    this.rogerBeepStyle = 'STANDARD',
    this.lcdColorMode = 'AMBER',
    this.squelchLevel = 3,
    this.volume = 0.85,
    this.isRadioFilterEnabled = true,
    this.hapticFeedback = true,
  });

  RadioConfig copyWith({
    String? serverUrl,
    String? roomCode,
    String? callSign,
    String? rogerBeepStyle,
    String? lcdColorMode,
    int? squelchLevel,
    double? volume,
    bool? isRadioFilterEnabled,
    bool? hapticFeedback,
  }) {
    return RadioConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      roomCode: roomCode ?? this.roomCode,
      callSign: callSign ?? this.callSign,
      rogerBeepStyle: rogerBeepStyle ?? this.rogerBeepStyle,
      lcdColorMode: lcdColorMode ?? this.lcdColorMode,
      squelchLevel: squelchLevel ?? this.squelchLevel,
      volume: volume ?? this.volume,
      isRadioFilterEnabled: isRadioFilterEnabled ?? this.isRadioFilterEnabled,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    );
  }
}
