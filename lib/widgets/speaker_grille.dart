import 'package:flutter/material.dart';

class SpeakerGrille extends StatefulWidget {
  final bool isReceiving;
  final bool isMonitorActive;

  const SpeakerGrille({
    super.key,
    required this.isReceiving,
    this.isMonitorActive = false,
  });

  @override
  State<SpeakerGrille> createState() => _SpeakerGrilleState();
}

class _SpeakerGrilleState extends State<SpeakerGrille> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isReceiving || widget.isMonitorActive;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final glowOpacity = active ? (0.2 + (_anim.value * 0.4)) : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF101215),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF22262D), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background green / amber audio glow during voice reception
              if (active)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00FF66).withOpacity(glowOpacity),
                        Colors.transparent,
                      ],
                      radius: 0.9,
                    ),
                  ),
                ),

              // Louver speaker slats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF090A0C),
                        borderRadius: BorderRadius.circular(2),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF2C323B),
                            width: 0.8,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Tactical text label
              Positioned(
                bottom: 2,
                child: Text(
                  'HIGH SENSITIVITY TRANSDUCER',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 6.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF5A6372),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
