import 'package:flutter/material.dart';

class AlertsSettingsScreen extends StatefulWidget {
  const AlertsSettingsScreen({super.key});
  @override
  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  bool _notifyDisconnect = true;
  bool _serverLoadAlert  = false;
  bool _newDeviceAlert   = true;
  bool _intrusionAlert   = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts & Notifications'), leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Text('Alert Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Choose when you want to be notified.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.55),
                  )),
          const SizedBox(height: 24),

          // Alert tiles
          Card(
            child: Column(
              children: [
                _alertTile(
                  context,
                  icon: Icons.link_off_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Device Disconnect',
                  subtitle: 'Alert when a monitored device goes offline',
                  value: _notifyDisconnect,
                  onChanged: (v) => setState(() => _notifyDisconnect = v),
                ),
                Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                _alertTile(
                  context,
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Server Load Threshold',
                  subtitle: 'Alert when server load exceeds threshold',
                  value: _serverLoadAlert,
                  onChanged: (v) => setState(() => _serverLoadAlert = v),
                ),
                Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                _alertTile(
                  context,
                  icon: Icons.devices_other_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'New Device Detected',
                  subtitle: 'Alert when an unknown device joins the network',
                  value: _newDeviceAlert,
                  onChanged: (v) => setState(() => _newDeviceAlert = v),
                ),
                Divider(height: 1, indent: 56, color: scheme.outline.withOpacity(0.3)),
                _alertTile(
                  context,
                  icon: Icons.shield_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Intrusion Detected',
                  subtitle: 'Alert on suspected security threat',
                  value: _intrusionAlert,
                  onChanged: (v) => setState(() => _intrusionAlert = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
