import 'package:flutter/material.dart';

class RefreshSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Refresh Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Refresh every 10 seconds option inside a Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  title: Text(
                    "Refresh every 10 seconds",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    // Handle the tap action here
                  },
                ),
              ),
              SizedBox(height: 16), // Space between items

              // Refresh every 30 seconds option inside a Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  title: Text(
                    "Refresh every 30 seconds",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    // Handle the tap action here
                  },
                ),
              ),
              SizedBox(height: 16),

              // Refresh every 1 minute option inside a Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  title: Text(
                    "Refresh every 1 minute",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    // Handle the tap action here
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
