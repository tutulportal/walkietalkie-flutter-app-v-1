import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TacticalKnob extends StatefulWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final VoidCallback? onStep;
  final bool isStepped;
  final int stepCount;
  final String displayValue;

  const TacticalKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onStep,
    this.isStepped = false,
    this.stepCount = 16,
    required this.displayValue,
  });

  @override
  State<TacticalKnob> createState() => _TacticalKnobState();
}

class _TacticalKnobState extends State<TacticalKnob> {
  double _dragStartAngle = 0.0;
  double _dragStartValue = 0.0;

  @override
  Widget build(BuildContext context) {
    // Map value 0.0..1.0 to rotation angle: -135 deg to +135 deg
    const minAngle = -135.0 * (pi / 180.0);
    const maxAngle = 135.0 * (pi / 180.0);
    final currentAngle = minAngle + (widget.value * (maxAngle - minAngle));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        GestureDetector(
          onPanStart: (details) {
            final box = context.findRenderObject() as RenderBox;
            final center = box.size.center(Offset.zero);
            _dragStartAngle = atan2(
              details.localPosition.dy - center.dy,
              details.localPosition.dx - center.dx,
            );
            _dragStartValue = widget.value;
          },
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            final center = box.size.center(Offset.zero);
            final currentTouchAngle = atan2(
              details.localPosition.dy - center.dy,
              details.localPosition.dx - center.dx,
            );

            double angleDiff = currentTouchAngle - _dragStartAngle;
            // Normalize wrap around
            if (angleDiff > pi) angleDiff -= 2 * pi;
            if (angleDiff < -pi) angleDiff += 2 * pi;

            final totalSpan = maxAngle - minAngle;
            final valueDelta = angleDiff / totalSpan;
            double newValue = (_dragStartValue + valueDelta).clamp(0.0, 1.0);

            if (widget.isStepped) {
              final stepIndex = (newValue * (widget.stepCount - 1)).round();
              newValue = stepIndex / (widget.stepCount - 1);
            }

            if ((newValue - widget.value).abs() > 0.01) {
              HapticFeedback.selectionClick();
              widget.onChanged(newValue);
              widget.onStep?.call();
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B1E22),
              border: Border.all(color: const Color(0xFF323842), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  offset: Offset(0, 3),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: Color(0xFF3F4652),
                  offset: Offset(0, -1),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Knurled grip outer ring
                CustomPaint(
                  size: const Size(44, 44),
                  painter: _KnobGripPainter(),
                ),

                // Rotating dial with pointer notch
                Transform.rotate(
                  angle: currentAngle,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF4A525E),
                          Color(0xFF282D35),
                          Color(0xFF15181C),
                        ],
                        stops: [0.2, 0.7, 1.0],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 3,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFFF5252),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.displayValue,
          style: const TextStyle(
            color: Color(0xFF00FF66),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _KnobGripPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = const Color(0xFF474F5A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const count = 20;
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i) / count;
      final x1 = center.dx + (radius - 4) * cos(angle);
      final y1 = center.dy + (radius - 4) * sin(angle);
      final x2 = center.dx + radius * cos(angle);
      final y2 = center.dy + radius * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
