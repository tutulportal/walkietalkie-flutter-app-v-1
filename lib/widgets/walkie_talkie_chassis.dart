import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/radio_channel.dart';
import '../models/radio_state.dart';
import 'lcd_screen.dart';
import 'tactical_knob.dart';
import 'ptt_button.dart';
import 'speaker_grille.dart';

class WalkieTalkieChassis extends StatelessWidget {
  final RadioChannel currentChannel;
  final RadioTransmissionState transmissionState;
  final ConnectionStateEnum connectionState;
  final RadioConfig config;
  final String? activeSpeakerCallsign;
  final int onlineUsersCount;
  final double volume;
  final bool isMonitorActive;
  final bool isScanning;

  // Interaction Callbacks
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onVolumeStep;
  final ValueChanged<int> onChannelSelected;
  final VoidCallback onChannelUp;
  final VoidCallback onChannelDown;
  final VoidCallback onPttDown;
  final VoidCallback onPttUp;
  final VoidCallback onMonitorToggle;
  final VoidCallback onCallAlert;
  final VoidCallback onScanToggle;
  final VoidCallback onOpenConfig;

  const WalkieTalkieChassis({
    super.key,
    required this.currentChannel,
    required this.transmissionState,
    required this.connectionState,
    required this.config,
    this.activeSpeakerCallsign,
    required this.onlineUsersCount,
    required this.volume,
    required this.isMonitorActive,
    required this.isScanning,
    required this.onVolumeChanged,
    required this.onVolumeStep,
    required this.onChannelSelected,
    required this.onChannelUp,
    required this.onChannelDown,
    required this.onPttDown,
    required this.onPttUp,
    required this.onMonitorToggle,
    required this.onCallAlert,
    required this.onScanToggle,
    required this.onOpenConfig,
  });

  @override
  Widget build(BuildContext context) {
    final isTx = transmissionState == RadioTransmissionState.transmitting;
    final isRx = transmissionState == RadioTransmissionState.receiving;
    final isBusy = transmissionState == RadioTransmissionState.busy;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Antenna & Rotary Knobs Cluster
              _buildTopAntennaAndKnobs(),

              // Main Rugged Walkie-Talkie Body
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2228),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  border: Border.all(color: const Color(0xFF333A44), width: 3.5),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black87,
                      offset: Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: isTx
                          ? Colors.redAccent.withOpacity(0.3)
                          : (isRx ? const Color(0xFF00FF66).withOpacity(0.2) : Colors.transparent),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Left and Right Rubber Grip Texture along edges
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSideGrip(isLeft: true),
                          _buildSideGrip(isLeft: false),
                        ],
                      ),
                    ),

                    // Front Face Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brand Label & Screws Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHexScrew(),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isTx
                                              ? Colors.redAccent
                                              : (isRx ? const Color(0xFF00FF66) : const Color(0xFF4A5568)),
                                          boxShadow: (isTx || isRx)
                                              ? [
                                                  BoxShadow(
                                                    color: isTx ? Colors.red : const Color(0xFF00FF66),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'TACTICAL TRANSCEIVER',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: Color(0xFFD4DCF0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'PMR446 / UHF FM DUAL SYNTHESIZED',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: const Color(0xFF7E8B9C),
                                    ),
                                  ),
                                ],
                              ),
                              _buildHexScrew(),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Authentic LCD Screen
                          LcdScreen(
                            currentChannel: currentChannel,
                            transmissionState: transmissionState,
                            connectionState: connectionState,
                            roomCode: config.roomCode,
                            callSign: config.callSign,
                            activeSpeakerCallsign: activeSpeakerCallsign,
                            onlineUsersCount: onlineUsersCount,
                            volume: volume,
                            squelchLevel: config.squelchLevel,
                            rogerBeepStyle: config.rogerBeepStyle,
                            colorMode: config.lcdColorMode,
                            isMonitorActive: isMonitorActive,
                            isScanning: isScanning,
                          ),

                          const SizedBox(height: 8),

                          // Speaker Grille with voice animation
                          SpeakerGrille(
                            isReceiving: isRx,
                            isMonitorActive: isMonitorActive,
                          ),

                          const SizedBox(height: 12),

                          // Tactical Control Buttons (CALL, MONI, SCAN, CH ▲, CH ▼, CONFIG)
                          _buildTacticalKeypad(context),

                          const SizedBox(height: 16),

                          // Huge Realistic Push-To-Talk (PTT) Button
                          PttButton(
                            isTransmitting: isTx,
                            isBusy: isBusy,
                            onPttDown: onPttDown,
                            onPttUp: onPttUp,
                          ),

                          const SizedBox(height: 14),

                          // Bottom Corner Screws & Mic Hole
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHexScrew(),
                              // Condenser Mic Hole
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'MIC',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                              _buildHexScrew(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAntennaAndKnobs() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Antenna on left
          _buildAntenna(),

          const Spacer(),

          // Volume Rotary Knob
          TacticalKnob(
            label: 'VOL / PWR',
            value: volume,
            displayValue: '${(volume * 100).toInt()}%',
            onChanged: onVolumeChanged,
            onStep: onVolumeStep,
          ),

          const SizedBox(width: 24),

          // Channel Rotary Knob
          TacticalKnob(
            label: 'CHANNEL',
            value: (currentChannel.number - 1) / 15.0,
            displayValue: 'CH-${currentChannel.number.toString().padLeft(2, '0')}',
            isStepped: true,
            stepCount: 16,
            onChanged: (val) {
              final newChanNum = (val * 15).round() + 1;
              onChannelSelected(newChanNum);
            },
            onStep: onVolumeStep,
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildAntenna() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Rounded rubber antenna tip
        Container(
          width: 14,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF1B1E22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              top: BorderSide(color: Color(0xFF38404B), width: 1.5),
              left: BorderSide(color: Color(0xFF38404B), width: 1.5),
              right: BorderSide(color: Color(0xFF38404B), width: 1.5),
            ),
          ),
        ),
        // Segmented antenna shaft with rib rings
        Container(
          width: 15,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E3540),
                Color(0xFF181C20),
                Color(0xFF0F1114),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
            border: Border.all(color: const Color(0xFF282D35), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (_) {
              return Container(
                height: 1.5,
                color: const Color(0xFF454F5E),
              );
            }),
          ),
        ),
        // Brass/Metal mounting base collar
        Container(
          width: 20,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF3B4452),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF5A6678), width: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildSideGrip({required bool isLeft}) {
    return Container(
      width: 12,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(10, (_) {
          return Container(
            width: 10,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF101215),
              borderRadius: isLeft
                  ? const BorderRadius.horizontal(right: Radius.circular(3))
                  : const BorderRadius.horizontal(left: Radius.circular(3)),
              border: Border.all(color: const Color(0xFF2C323C), width: 0.8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHexScrew() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2A2F38),
        border: Border.all(color: const Color(0xFF4A5565), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF15181D),
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalKeypad(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: [
          // Row 1: CALL, MONI, SCAN
          Row(
            children: [
              // CALL Alert Button
              Expanded(
                child: _buildKeypadButton(
                  label: 'CALL',
                  icon: Icons.notifications_active,
                  accentColor: const Color(0xFFFF5252),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    onCallAlert();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // MONI (Squelch Monitor) Button
              Expanded(
                child: _buildKeypadButton(
                  label: 'MONI',
                  icon: Icons.graphic_eq,
                  accentColor: isMonitorActive ? const Color(0xFF00FF66) : const Color(0xFF90A4AE),
                  isActive: isMonitorActive,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onMonitorToggle();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // SCAN Button
              Expanded(
                child: _buildKeypadButton(
                  label: 'SCAN',
                  icon: Icons.radar,
                  accentColor: isScanning ? Colors.amberAccent : const Color(0xFF90A4AE),
                  isActive: isScanning,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onScanToggle();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: CH UP, CH DOWN, CONFIG
          Row(
            children: [
              // Channel Down
              Expanded(
                child: _buildKeypadButton(
                  label: 'CH ▼',
                  icon: Icons.keyboard_arrow_down,
                  accentColor: const Color(0xFF00E5FF),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChannelDown();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Channel Up
              Expanded(
                child: _buildKeypadButton(
                  label: 'CH ▲',
                  icon: Icons.keyboard_arrow_up,
                  accentColor: const Color(0xFF00E5FF),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChannelUp();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // CONFIG / SERVER SETTINGS Button
              Expanded(
                child: _buildKeypadButton(
                  label: 'CONFIG',
                  icon: Icons.settings,
                  accentColor: const Color(0xFFFF9E1B),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onOpenConfig();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton({
    required String label,
    required IconData icon,
    required Color accentColor,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? accentColor.withOpacity(0.22) : const Color(0xFF13161A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? accentColor : const Color(0xFF2E3540),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? accentColor : const Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isActive ? accentColor : const Color(0xFFD8E2EC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
