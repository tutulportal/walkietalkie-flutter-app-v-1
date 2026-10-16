import 'package:flutter/material.dart';
import '../models/radio_state.dart';
import '../services/audio_manager.dart';

class SettingsDialog extends StatefulWidget {
  final RadioConfig config;
  final AudioManager audioManager;
  final ValueChanged<RadioConfig> onSave;

  const SettingsDialog({
    super.key,
    required this.config,
    required this.audioManager,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _serverController;
  late TextEditingController _roomCodeController;
  late TextEditingController _callSignController;
  late String _selectedRogerBeep;
  late String _selectedLcdColor;
  late int _squelchLevel;
  late bool _radioFilter;

  final List<String> _rogerBeepOptions = [
    'STANDARD',
    'BAOFENG',
    'KENWOOD_DUAL',
    'NASA_QUINDAR',
    'MILITARY_TRIAD',
    'OFF',
  ];

  final List<String> _lcdColors = [
    'AMBER',
    'GREEN',
    'CYAN',
    'WHITE',
  ];

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController(text: widget.config.serverUrl);
    _roomCodeController = TextEditingController(text: widget.config.roomCode);
    _callSignController = TextEditingController(text: widget.config.callSign);
    _selectedRogerBeep = widget.config.rogerBeepStyle;
    _selectedLcdColor = widget.config.lcdColorMode;
    _squelchLevel = widget.config.squelchLevel;
    _radioFilter = widget.config.isRadioFilterEnabled;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _roomCodeController.dispose();
    _callSignController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.config.copyWith(
      serverUrl: _serverController.text.trim().isEmpty
          ? 'wss://walkietalkie-flutter-app-v-1.onrender.com'
          : _serverController.text.trim(),
      roomCode: _roomCodeController.text.trim().isEmpty
          ? 'ALPHA'
          : _roomCodeController.text.trim().toUpperCase(),
      callSign: _callSignController.text.trim().isEmpty
          ? 'VIPER-01'
          : _callSignController.text.trim().toUpperCase(),
      rogerBeepStyle: _selectedRogerBeep,
      lcdColorMode: _selectedLcdColor,
      squelchLevel: _squelchLevel,
      isRadioFilterEnabled: _radioFilter,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF181B20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF38404D), width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.settings, color: Color(0xFFFF9E1B), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'RADIO CONFIGURATION',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2C323D)),
              const SizedBox(height: 12),

              // Server URL Section
              _buildSectionTitle('SERVER CONNECTION (WEBSOCKET)', Icons.wifi_tethering),
              const SizedBox(height: 6),
              TextField(
                controller: _serverController,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF00FF66),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'wss://walkietalkie-flutter-app-v-1.onrender.com',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF101215),
                  prefixIcon: const Icon(Icons.dns, color: Color(0xFFFF9E1B), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2E3540)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2E3540)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF9E1B)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Preset server chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildQuickUrlChip('wss://walkietalkie-flutter-app-v-1.onrender.com', 'Render Cloud'),
                  _buildQuickUrlChip('ws://localhost:8080', 'Local PC'),
                  _buildQuickUrlChip('ws://10.0.2.2:8080', 'Android Emu'),
                ],
              ),

              const SizedBox(height: 16),

              // Server Code / Group Channel Section
              _buildSectionTitle('SERVER CODE / NETWORK ROOM', Icons.lock_outline),
              const SizedBox(height: 4),
              const Text(
                'Radios with the same Server Code & Channel tune to the exact same frequency!',
                style: TextStyle(color: Color(0xFF8F9BA8), fontSize: 11),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _roomCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFFF9E1B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. ALPHA, SQUAD-1, TACTICAL',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF101215),
                  prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFFFF9E1B), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2E3540)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Callsign / Radio ID
              _buildSectionTitle('RADIO CALL SIGN / IDENTIFIER', Icons.badge_outlined),
              const SizedBox(height: 6),
              TextField(
                controller: _callSignController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. VIPER-01, BRAVO-LEAD',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF101215),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFFFF9E1B), size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2E3540)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Roger Beep Selection + Audio Preview
              _buildSectionTitle('ROGER BEEP TONE SOUND', Icons.volume_up),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF101215),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E3540)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRogerBeep,
                          dropdownColor: const Color(0xFF181B20),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF9E1B)),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          items: _rogerBeepOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt.replaceAll('_', ' ')),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRogerBeep = val);
                              widget.audioManager.playRogerBeep(val);
                            }
                          },
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B333E),
                        foregroundColor: const Color(0xFFFF9E1B),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        widget.audioManager.playRogerBeep(_selectedRogerBeep);
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('TEST', style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // LCD Backlight Theme Color
              _buildSectionTitle('LCD DISPLAY BACKLIGHT COLOR', Icons.palette_outlined),
              const SizedBox(height: 6),
              Row(
                children: _lcdColors.map((colorName) {
                  final isSelected = _selectedLcdColor == colorName;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLcdColor = colorName),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _getColorSample(colorName),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.2,
                          ),
                        ),
                        child: Text(
                          colorName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colorName == 'WHITE' ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Squelch Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('SQUELCH THRESHOLD', Icons.tune),
                  Text(
                    'LEVEL: $_squelchLevel',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFFF9E1B),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFFFF9E1B),
                  inactiveTrackColor: const Color(0xFF2E3540),
                  thumbColor: const Color(0xFFFF9E1B),
                  overlayColor: const Color(0xFFFF9E1B).withOpacity(0.2),
                ),
                child: Slider(
                  value: _squelchLevel.toDouble(),
                  min: 1,
                  max: 9,
                  divisions: 8,
                  onChanged: (val) {
                    setState(() => _squelchLevel = val.round());
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Creator & Lead Developer Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF101215),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF9E1B).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.military_tech, color: Color(0xFFFF9E1B), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'SYSTEM CREATOR & ARCHITECT',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFFF9E1B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Creator: Tutul',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'GitHub: @tutulportal',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF00FF66),
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Project: walkietalkie-flutter-app-v-1',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF90A4AE),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Save & Apply Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9E1B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                onPressed: _save,
                child: const Text(
                  'APPLY & CONNECT RADIO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFF9E1B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFC0CAD6),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickUrlChip(String url, String label) {
    return ActionChip(
      backgroundColor: const Color(0xFF222831),
      side: const BorderSide(color: Color(0xFF37404E)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: Color(0xFFD2DBE5),
        ),
      ),
      onPressed: () {
        setState(() {
          _serverController.text = url;
        });
      },
    );
  }

  Color _getColorSample(String color) {
    switch (color) {
      case 'GREEN':
        return const Color(0xFF275421);
      case 'CYAN':
        return const Color(0xFF15485E);
      case 'WHITE':
        return const Color(0xFFECEFF1);
      case 'AMBER':
      default:
        return const Color(0xFF6B420C);
    }
  }
}
