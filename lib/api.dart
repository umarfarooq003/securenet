import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiPage extends StatefulWidget {
  @override
  _ApiPageState createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  @override
  void initState() {
    super.initState();
    fetchApiData();
  }

  Future<void> fetchApiData() async {
    const url =
        'https://new-folder-3-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graph';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode ==201) {
        final body = jsonDecode(response.body);
        print("✅ API Response:");
        print(body);
      } else {
        print(" Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Console API Fetch"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Text(
          'Check console for API output',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
