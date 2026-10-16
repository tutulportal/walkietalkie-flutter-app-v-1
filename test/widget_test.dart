import 'package:flutter_test/flutter_test.dart';
import 'package:walkie_talkie/models/radio_channel.dart';
import 'package:walkie_talkie/services/sound_generator.dart';

void main() {
  test('RadioChannel default channels test', () {
    expect(RadioChannel.defaultChannels.length, equals(16));
    expect(RadioChannel.defaultChannels[0].channelDisplay, equals('CH-01'));
    expect(RadioChannel.defaultChannels[0].formattedFrequency, equals('446.0062'));
  });

  test('SoundGenerator produces valid WAV bytes', () {
    final chirp = SoundGenerator.createPttPressChirp();
    expect(chirp.length, greaterThan(44));
    // Check RIFF header
    expect(chirp[0], equals(0x52)); // 'R'
    expect(chirp[1], equals(0x49)); // 'I'
    expect(chirp[2], equals(0x46)); // 'F'
    expect(chirp[3], equals(0x46)); // 'F'

    final squelch = SoundGenerator.createSquelchTail();
    expect(squelch.length, greaterThan(44));

    final roger = SoundGenerator.createRogerBeep('STANDARD');
    expect(roger.length, greaterThan(44));
  });
}
