import 'package:flutter/material.dart';
import 'package:login/main.dart'; // to access themeNotifier
import 'package:login/setting/about_screen.dart';
import 'package:login/setting/alerts_settings_screen.dart';
import 'package:login/setting/auth_settings_screen.dart';
import 'package:login/setting/backup_export_screen.dart';
import 'package:login/setting/discovery_settings_screen.dart';
import 'package:login/setting/neo4jsettingscreen.dart';
import 'package:login/setting/refresh_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        bool isDarkMode = themeMode == ThemeMode.dark;

        return Scaffold(
          body: ListView(
            children: [
              ListTile(
                leading: Icon(Icons.brightness_6),
                title: Text("Dark Mode"),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (val) {
                    themeNotifier.value =
                    val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              Divider(),

              ListTile(
                leading: Icon(Icons.storage),
                title: Text("Neo4j Connection Settings"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Neo4jSettingsScreen())),
              ),

              ListTile(
                leading: Icon(Icons.refresh),
                title: Text("Data Refresh Settings"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RefreshSettingsScreen())),
              ),

              ListTile(
                leading: Icon(Icons.network_check),
                title: Text("Network Discovery Preferences"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DiscoverySettingsScreen())),
              ),

              Divider(),

              ListTile(
                leading: Icon(Icons.notifications),
                title: Text("Alerts & Notifications"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AlertsSettingsScreen())),
              ),

              ListTile(
                leading: Icon(Icons.backup),
                title: Text("Backup & Export"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BackupExportScreen())),
              ),

              Divider(),

              ListTile(
                leading: Icon(Icons.security),
                title: Text("User Authentication"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AuthSettingsScreen())),
              ),

              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("About"),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutScreen())),
              ),
            ],
          ),
        );
      },
    );
  }
}

