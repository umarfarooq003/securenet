import 'package:flutter/material.dart';

import '../CSV file/csv.dart';

class BackupExportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Backup & Export")),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for overall spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Data option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Padding inside ListTile
                leading: Icon(Icons.file_download, color: Colors.blue, size: 30),
                title: Text(
                  "Export Data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExportCSVScreen()),
                  );
                },
              ),
            ),
            SizedBox(height: 16), // Space between items

            // Import Configuration option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                leading: Icon(Icons.file_upload, color: Colors.green, size: 30),
                title: Text(
                  "Import Configuration",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  // Add functionality for importing configuration
                },
              ),
            ),
            SizedBox(height: 16), // Space between items

            // Clear App Data option (Card style)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                leading: Icon(Icons.delete, color: Colors.red, size: 30),
                title: Text(
                  "Clear App Data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  // Add functionality to clear app data
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
