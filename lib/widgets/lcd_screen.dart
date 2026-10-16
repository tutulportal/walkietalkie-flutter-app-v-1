import 'package:flutter/material.dart';
import '../models/radio_channel.dart';
import '../models/radio_state.dart';

class LcdScreen extends StatelessWidget {
  final RadioChannel currentChannel;
  final RadioTransmissionState transmissionState;
  final ConnectionStateEnum connectionState;
  final String roomCode;
  final String callSign;
  final String? activeSpeakerCallsign;
  final int onlineUsersCount;
  final double volume;
  final int squelchLevel;
  final String rogerBeepStyle;
  final String colorMode;
  final bool isMonitorActive;
  final bool isScanning;

  const LcdScreen({
    super.key,
    required this.currentChannel,
    required this.transmissionState,
    required this.connectionState,
    required this.roomCode,
    required this.callSign,
    this.activeSpeakerCallsign,
    required this.onlineUsersCount,
    required this.volume,
    required this.squelchLevel,
    required this.rogerBeepStyle,
    this.colorMode = 'AMBER',
    this.isMonitorActive = false,
    this.isScanning = false,
  });

  Color _getLcdBg() {
    switch (colorMode.toUpperCase()) {
      case 'GREEN':
        return const Color(0xFF1E3A1A);
      case 'CYAN':
        return const Color(0xFF0F2E3D);
      case 'WHITE':
        return const Color(0xFF2A2E33);
      case 'AMBER':
      default:
        return const Color(0xFF332005);
    }
  }

  Color _getLcdText() {
    switch (colorMode.toUpperCase()) {
      case 'GREEN':
        return const Color(0xFF4AF626);
      case 'CYAN':
        return const Color(0xFF00E5FF);
      case 'WHITE':
        return const Color(0xFFE2E8F0);
      case 'AMBER':
      default:
        return const Color(0xFFFF9E1B);
    }
  }

  Color _getLcdDim() {
    return _getLcdText().withOpacity(0.18);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getLcdText();
    final dimColor = _getLcdDim();
    final isTx = transmissionState == RadioTransmissionState.transmitting;
    final isRx = transmissionState == RadioTransmissionState.receiving;
    final isBusy = transmissionState == RadioTransmissionState.busy;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14171A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2E35), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0xFF2D333B),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getLcdBg(),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status Bar: Signal RSSI, Status Icons, Battery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // RSSI Signal Bars
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SIG ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    _buildRssiBar(1, 4, textColor, connectionState == ConnectionStateEnum.connected),
                    const SizedBox(width: 2),
                    _buildRssiBar(2, 7, textColor, connectionState == ConnectionStateEnum.connected),
                    const SizedBox(width: 2),
                    _buildRssiBar(3, 10, textColor, connectionState == ConnectionStateEnum.connected),
                    const SizedBox(width: 2),
                    _buildRssiBar(4, 13, textColor, connectionState == ConnectionStateEnum.connected),
                    const SizedBox(width: 2),
                    _buildRssiBar(5, 16, textColor, connectionState == ConnectionStateEnum.connected),
                  ],
                ),

                // Middle Indicators (SQL, ROG, SCAN)
                Row(
                  children: [
                    _buildSmallBadge(
                      'SQL:$squelchLevel',
                      isMonitorActive ? Colors.redAccent : textColor,
                      isMonitorActive,
                    ),
                    const SizedBox(width: 4),
                    _buildSmallBadge('ROG', textColor, rogerBeepStyle != 'OFF'),
                    if (isScanning) ...[
                      const SizedBox(width: 4),
                      _buildSmallBadge('SCAN', Colors.amberAccent, true),
                    ],
                  ],
                ),

                // Battery Icon
                Row(
                  children: [
                    Text(
                      'BAT ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 12,
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        border: Border.all(color: textColor, width: 1.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Container(color: textColor)),
                          const SizedBox(width: 1),
                          Expanded(child: Container(color: textColor)),
                          const SizedBox(width: 1),
                          Expanded(child: Container(color: textColor)),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 5,
                      color: textColor,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Middle Section: Giant Channel & Frequency & Status Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big Digital Channel Indicator
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentChannel.channelDisplay,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: textColor,
                          shadows: [
                            Shadow(
                              color: textColor.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${currentChannel.formattedFrequency} MHz',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: textColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // TX / RX / BUSY Glow Status Indicators
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        _buildTxRxIndicator(
                          'TX',
                          Colors.redAccent,
                          isTx,
                          pulse: isTx,
                        ),
                        const SizedBox(width: 6),
                        _buildTxRxIndicator(
                          'RX',
                          const Color(0xFF00FF66),
                          isRx || isMonitorActive,
                          pulse: isRx,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isBusy)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          border: Border.all(color: Colors.redAccent, width: 1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'BUSY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                        ),
                      )
                    else
                      Text(
                        currentChannel.name,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: textColor.withOpacity(0.75),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Divider line with subtle dot matrix look
            Container(
              height: 1,
              color: dimColor,
            ),

            const SizedBox(height: 5),

            // Bottom Info Bar: Room Code / Call Sign / Active Speaker / Connection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Server Room Code
                Row(
                  children: [
                    Text(
                      'CODE: ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      roomCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                // Active Speaker or CallSign
                Flexible(
                  child: Text(
                    isRx
                        ? '◀ SPK: ${activeSpeakerCallsign ?? "INCOMING"}'
                        : isTx
                            ? '▶ TX: $callSign'
                            : 'ID: $callSign',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: (isRx || isTx) ? FontWeight.w900 : FontWeight.bold,
                      color: isRx
                          ? const Color(0xFF00FF66)
                          : isTx
                              ? Colors.redAccent
                              : textColor,
                    ),
                  ),
                ),

                // Connected Users Badge
                Row(
                  children: [
                    Icon(
                      Icons.people_alt,
                      size: 11,
                      color: textColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      connectionState == ConnectionStateEnum.connected
                          ? '$onlineUsersCount'
                          : 'DISC',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: connectionState == ConnectionStateEnum.connected
                            ? textColor
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRssiBar(int index, double height, Color activeColor, bool isConnected) {
    final isActive = isConnected;
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: isActive ? activeColor : activeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildSmallBadge(String label, Color color, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.2) : Colors.transparent,
        border: Border.all(
          color: active ? color : color.withOpacity(0.3),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: active ? color : color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildTxRxIndicator(String label, Color glowColor, bool isActive, {bool pulse = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? glowColor.withOpacity(0.25) : const Color(0xFF1E2124),
        border: Border.all(
          color: isActive ? glowColor : const Color(0xFF383E47),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? glowColor : const Color(0xFF48505B),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isActive ? glowColor : const Color(0xFF707A8A),
            ),
          ),
        ],
      ),
    );
  }
}
