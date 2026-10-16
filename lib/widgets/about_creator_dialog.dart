import 'package:flutter/material.dart';

class AboutCreatorDialog extends StatelessWidget {
  const AboutCreatorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF14171C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF9E1B), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9E1B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF9E1B)),
                  ),
                  child: const Icon(Icons.military_tech, color: Color(0xFFFF9E1B), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ABOUT THE CREATOR',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFFF9E1B),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Official System Credits & Specs',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF90A4AE),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2E3540), height: 1),
            const SizedBox(height: 16),

            // Creator Profile Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1114),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E3540)),
              ),
              child: Column(
                children: [
                  // Avatar & Name
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9E1B), Color(0xFFFF5252)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9E1B).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'T',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Tutul',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Lead Architect & Creator',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFFFF9E1B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'GitHub: @tutulportal',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFF00FF66),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF1E2228), height: 1),
                  const SizedBox(height: 12),

                  _buildInfoRow('Project', 'Walkie-Talkie Tactical App'),
                  _buildInfoRow('Repository', 'walkietalkie-flutter-app-v-1'),
                  _buildInfoRow('Server', 'Render Cloud Node.js Relay'),
                  _buildInfoRow('Protocol', 'WebSocket Secure (WSS) + PCM'),
                  _buildInfoRow('Compatibility', 'Android 5.0 - 15 (Universal)'),
                  _buildInfoRow('Audio Mode', 'High-Gain Speakerphone 24/7'),
                  _buildInfoRow('Version', 'v1.0.0+1 Tactical Release'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9E1B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'DISMISS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF78909C),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFFECEFF1),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
