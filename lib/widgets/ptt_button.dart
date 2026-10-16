import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PttButton extends StatefulWidget {
  final bool isTransmitting;
  final bool isBusy;
  final VoidCallback onPttDown;
  final VoidCallback onPttUp;

  const PttButton({
    super.key,
    required this.isTransmitting,
    required this.isBusy,
    required this.onPttDown,
    required this.onPttUp,
  });

  @override
  State<PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends State<PttButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDown() {
    if (widget.isBusy) {
      HapticFeedback.vibrate();
      return;
    }
    setState(() => _isPressed = true);
    HapticFeedback.heavyImpact();
    widget.onPttDown();
  }

  void _handleUp() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      HapticFeedback.mediumImpact();
      widget.onPttUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTx = widget.isTransmitting || _isPressed;

    return GestureDetector(
      onTapDown: (_) => _handleDown(),
      onTapUp: (_) => _handleUp(),
      onTapCancel: () => _handleUp(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulseVal = _pulseController.value;
          final glowRadius = isTx ? 12.0 + (pulseVal * 8.0) : 4.0;
          final glowColor = isTx
              ? Colors.redAccent.withOpacity(0.8)
              : (widget.isBusy
                  ? Colors.amber.withOpacity(0.4)
                  : Colors.black54);

          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF131518),
              border: Border.all(
                color: isTx
                    ? Colors.redAccent
                    : (widget.isBusy ? Colors.amber : const Color(0xFF2C323B)),
                width: isTx ? 3.5 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: glowRadius,
                  spreadRadius: isTx ? 3 : 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: isTx ? const Offset(0, 2) : const Offset(0, 8),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                width: isTx ? 116 : 122,
                height: isTx ? 116 : 122,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isTx
                        ? [
                            const Color(0xFF8B0000),
                            const Color(0xFF4A0000),
                            const Color(0xFF200000),
                          ]
                        : [
                            const Color(0xFF373E47),
                            const Color(0xFF20242A),
                            const Color(0xFF14171A),
                          ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: isTx ? const Color(0xFFFF5252) : const Color(0xFF4B5360),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rubber Grip Ridges across face
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _PttRibPainter(isTx: isTx),
                    ),

                    // Center Tactical Label
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTx ? Icons.mic : (widget.isBusy ? Icons.mic_off : Icons.mic_none),
                          color: isTx
                              ? Colors.white
                              : (widget.isBusy ? Colors.amber : const Color(0xFFB0B8C4)),
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTx
                              ? 'TRANSMITTING'
                              : (widget.isBusy ? 'CHANNEL BUSY' : 'PUSH TO TALK'),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isTx ? 10.5 : 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isTx
                                ? Colors.white
                                : (widget.isBusy
                                    ? Colors.amber
                                    : const Color(0xFFD1D7E0)),
                            shadows: isTx
                                ? const [
                                    Shadow(
                                      color: Colors.red,
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTx ? 'RELEASE TO OVER' : 'HOLD TO TALK',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: isTx
                                ? Colors.white70
                                : const Color(0xFF808B99),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PttRibPainter extends CustomPainter {
  final bool isTx;
  _PttRibPainter({required this.isTx});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()
      ..color = (isTx ? Colors.red.withOpacity(0.3) : const Color(0xFF48505C))
      ..strokeWidth = 2.0;

    final paintDark = Paint()
      ..color = (isTx ? Colors.black45 : const Color(0xFF101215))
      ..strokeWidth = 1.5;

    // Draw 5 horizontal grip stripes
    final centerY = size.height / 2;
    for (int i = -2; i <= 2; i++) {
      final y = centerY + (i * 18.0);
      final width = 64.0 - (i.abs() * 12.0);
      final startX = (size.width - width) / 2;
      final endX = startX + width;

      // Draw subtle shadow and highlight line
      canvas.drawLine(Offset(startX, y - 1), Offset(endX, y - 1), paintLight);
      canvas.drawLine(Offset(startX, y + 1), Offset(endX, y + 1), paintDark);
    }
  }

  @override
  bool shouldRepaint(covariant _PttRibPainter oldDelegate) => oldDelegate.isTx != isTx;
}
