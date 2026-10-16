import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class StartupPermissionDialog extends StatefulWidget {
  final VoidCallback onPermissionsCompleted;

  const StartupPermissionDialog({
    super.key,
    required this.onPermissionsCompleted,
  });

  static Future<void> checkAndShow(BuildContext context) async {
    if (kIsWeb) return;
    final mic = await Permission.microphone.isGranted;
    final notif = await Permission.notification.isGranted;

    // If permissions are missing, show tactical request modal
    if (!mic || !notif) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StartupPermissionDialog(
            onPermissionsCompleted: () {
              Navigator.of(ctx).pop();
            },
          ),
        );
      }
    }
  }

  @override
  State<StartupPermissionDialog> createState() => _StartupPermissionDialogState();
}

class _StartupPermissionDialogState extends State<StartupPermissionDialog> {
  bool _isRequesting = false;

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequesting = true);

    try {
      // 1. Microphone for voice transmission
      await Permission.microphone.request();

      // 2. Notifications for background incoming audio notifications
      await Permission.notification.request();

      // 3. Ignore Battery Optimizations for persistent background connection
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('[Permission] error requesting: $e');
    }

    if (mounted) {
      setState(() => _isRequesting = false);
      widget.onPermissionsCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF14171C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00FF66), width: 1.5),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00FF66)),
                  ),
                  child: const Icon(Icons.security, color: Color(0xFF00FF66), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'RADIO PERMISSIONS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00FF66),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Required for 24/7 background audio',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF90A4AE),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(color: Color(0xFF2E3540), height: 1),
            const SizedBox(height: 16),

            // Permission items
            _buildPermItem(
              icon: Icons.mic,
              iconColor: const Color(0xFFFF9E1B),
              title: 'Microphone Access',
              desc: 'Allows transmitting your voice instantly when pressing the PTT button.',
            ),
            const SizedBox(height: 12),

            _buildPermItem(
              icon: Icons.notifications_active,
              iconColor: const Color(0xFF00E5FF),
              title: 'Notifications & Foreground Service',
              desc: 'Enables background voice receiving so you hear transmissions even while in other apps.',
            ),
            const SizedBox(height: 12),

            _buildPermItem(
              icon: Icons.battery_charging_full,
              iconColor: const Color(0xFF00FF66),
              title: 'Background Battery Optimization Exemption',
              desc: 'Prevents Android OS from freezing the radio socket when your screen is locked.',
            ),

            const SizedBox(height: 22),

            // Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF66),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              onPressed: _isRequesting ? null : _requestAllPermissions,
              child: _isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text(
                      'ALLOW ALL PERMISSIONS & ACTIVATE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: iconColor.withOpacity(0.4)),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF8898AA),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
