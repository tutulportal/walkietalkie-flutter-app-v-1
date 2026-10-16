/// Model for radio channels and frequency specifications
class RadioChannel {
  final int number;
  final String name;
  final double frequencyMhz;
  final double defaultCtcssHz;

  const RadioChannel({
    required this.number,
    required this.name,
    required this.frequencyMhz,
    this.defaultCtcssHz = 67.0,
  });

  String get formattedFrequency => frequencyMhz.toStringAsFixed(4);
  String get channelDisplay => 'CH-${number.toString().padLeft(2, '0')}';

  static const List<RadioChannel> defaultChannels = [
    RadioChannel(number: 1, name: 'EMERGENCY / CALL', frequencyMhz: 446.0062, defaultCtcssHz: 67.0),
    RadioChannel(number: 2, name: 'TACTICAL 2', frequencyMhz: 446.0187, defaultCtcssHz: 71.9),
    RadioChannel(number: 3, name: 'BASE COMMAND', frequencyMhz: 446.0312, defaultCtcssHz: 74.4),
    RadioChannel(number: 4, name: 'RECON / PATROL', frequencyMhz: 446.0437, defaultCtcssHz: 77.0),
    RadioChannel(number: 5, name: 'SECURITY OPS', frequencyMhz: 446.0562, defaultCtcssHz: 79.7),
    RadioChannel(number: 6, name: 'LOGISTICS CONVOY', frequencyMhz: 446.0687, defaultCtcssHz: 82.5),
    RadioChannel(number: 7, name: 'DISPATCH PRIMARY', frequencyMhz: 446.0812, defaultCtcssHz: 85.4),
    RadioChannel(number: 8, name: 'COMMON CH-8', frequencyMhz: 446.0937, defaultCtcssHz: 88.5),
    RadioChannel(number: 9, name: 'HAZMAT / RESCUE', frequencyMhz: 446.1062, defaultCtcssHz: 91.5),
    RadioChannel(number: 10, name: 'PERIMETER DEFENSE', frequencyMhz: 446.1187, defaultCtcssHz: 94.8),
    RadioChannel(number: 11, name: 'AIR SUPPORT', frequencyMhz: 446.1312, defaultCtcssHz: 97.4),
    RadioChannel(number: 12, name: 'SCOUT UNIT', frequencyMhz: 446.1437, defaultCtcssHz: 100.0),
    RadioChannel(number: 13, name: 'FIELD MEDICAL', frequencyMhz: 446.1562, defaultCtcssHz: 103.5),
    RadioChannel(number: 14, name: 'VIP PROTECTION', frequencyMhz: 446.1687, defaultCtcssHz: 107.2),
    RadioChannel(number: 15, name: 'EVENT STAFF', frequencyMhz: 446.1812, defaultCtcssHz: 110.9),
    RadioChannel(number: 16, name: 'INTER-AGENCY', frequencyMhz: 446.1937, defaultCtcssHz: 114.8),
  ];
}
