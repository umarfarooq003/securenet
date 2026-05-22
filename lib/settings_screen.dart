import 'package:flutter/material.dart';
import 'package:login/main.dart';
import 'package:login/setting/about_screen.dart';
import 'package:login/setting/alerts_settings_screen.dart';
import 'package:login/setting/auth_settings_screen.dart';
import 'package:login/setting/backup_export_screen.dart';
import 'package:login/setting/discovery_settings_screen.dart';
import 'package:login/setting/neo4jsettingscreen.dart';
import 'widgets/shared_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Manage your app preferences.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.55),
                    ),
              ),
            ),

            // ── Appearance ───────────────────────────────────────────────────
            const SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
            SettingsGroup(children: [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(isDark ? 'Using dark theme' : 'Using light theme'),
                value: isDark,
                onChanged: (v) => themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light,
              ),
            ]),

            // ── Network ──────────────────────────────────────────────────────
            const SectionHeader(title: 'Network', icon: Icons.network_check_outlined),
            SettingsGroup(children: [
              _navTile(
                context,
                icon: Icons.storage_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Neo4j Connection',
                subtitle: 'Configure database host & credentials',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Neo4jSettingsScreen())),
              ),
              _navTile(
                context,
                icon: Icons.radar_rounded,
                iconColor: const Color(0xFF14B8A6),
                title: 'Network Discovery',
                subtitle: 'IP range and SNMP settings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiscoverySettingsScreen())),
              ),
            ]),

            // ── Alerts ───────────────────────────────────────────────────────
            const SectionHeader(title: 'Alerts & Data', icon: Icons.notifications_none_outlined),
            SettingsGroup(children: [
              _navTile(
                context,
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Alerts & Notifications',
                subtitle: 'Device disconnect and load alerts',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertsSettingsScreen())),
              ),
              _navTile(
                context,
                icon: Icons.backup_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Backup & Export',
                subtitle: 'Export data, import config',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackupExportScreen())),
              ),
            ]),

            // ── Account ──────────────────────────────────────────────────────
            const SectionHeader(title: 'Account', icon: Icons.person_outline_rounded),
            SettingsGroup(children: [
              _navTile(
                context,
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Authentication',
                subtitle: 'Change password & sign-out options',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthSettingsScreen())),
              ),
              _navTile(
                context,
                icon: Icons.info_outline_rounded,
                iconColor: scheme.primary,
                title: 'About Detectome',
                subtitle: 'Version, developer info',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen())),
              ),
            ]),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded,
          color: scheme.onSurface.withOpacity(0.35), size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
