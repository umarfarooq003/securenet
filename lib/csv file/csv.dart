import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportCSVScreen extends StatefulWidget {
  @override
  _ExportCSVScreenState createState() => _ExportCSVScreenState();
}

class _ExportCSVScreenState extends State<ExportCSVScreen> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<Map<String, dynamic>>? data; // List to store all the data
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
    _checkPermissionsAndLoadData();
  }

  Future<void> _checkPermissionsAndLoadData() async {
    await _requestPermissions();
    await _loadData();
  }

  Future<void> _requestPermissions() async {
    // Request storage permissions (for Android < 10)
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    // Request notification permission (for Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _loadData() async {
    try {
      final fetchedData = await fetchDataFromAPI();
      setState(() {
        data = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchDataFromAPI() async {
    final apiUrl = 'https://new-folder-3-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graph';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> rawData = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(rawData);
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  // Convert the data to CSV
  String _toCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    List<List<dynamic>> rows = [];

    // Extract headers from the first item (you can customize the headers if needed)
    var headers = data.first.keys.toList();
    rows.add(headers);

    // Add each row of data
    for (var item in data) {
      List<dynamic> row = [];
      for (var header in headers) {
        row.add(item[header] ?? ''); // Add the value or empty if null
      }
      rows.add(row);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> _exportCSV(String content) async {
    try {
      final directory = await getExternalStorageDirectory(); // external dir
      final path = "${directory!.path}/network_data.csv";
      final file = File(path);
      await file.writeAsString(content);

      // Notify
      _showNotification("CSV Exported", "CSV file saved to $path");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("CSV saved to $path"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed: $e")),
      );
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'csv_export_channel',
      'CSV Export',
      channelDescription: 'Channel for CSV export notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (error != null) return _buildError();

    final csv = _toCSV(data!); // Use data (list of maps) to create CSV
    return Scaffold(
      appBar: AppBar(title: Text("Export CSV")),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.file_download),
          label: Text("Export Data"),
          onPressed: () => _exportCSV(csv),
        ),
      ),
    );
  }

  Widget _buildLoading() => Scaffold(
    appBar: AppBar(title: Text("Loading...")),
    body: Center(child: CircularProgressIndicator()),
  );

  Widget _buildError() => Scaffold(
    appBar: AppBar(title: Text("Error")),
    body: Center(child: Text("Error: $error")),
  );
}
