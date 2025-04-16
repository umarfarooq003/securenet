import 'package:flutter/material.dart';

class AlertsSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Alerts & Notifications")),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notify on device disconnect option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Add padding to SwitchListTile
                title: Text(
                  "Notify on device disconnect",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                value: true,
                onChanged: (val) {
                  // Handle the toggle action
                },
              ),
            ),
            SizedBox(height: 16), // Space between items

            // Server load threshold alert option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                title: Text(
                  "Server load threshold alert",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                value: false,
                onChanged: (val) {
                  // Handle the toggle action
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
