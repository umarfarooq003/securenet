import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Neo4jSettingsScreen extends StatefulWidget {
  @override
  _Neo4jSettingsScreenState createState() => _Neo4jSettingsScreenState();
}

class _Neo4jSettingsScreenState extends State<Neo4jSettingsScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _connectionStatus = '';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    final host = _hostController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _connectionStatus = "⚠️ Please fill all fields.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _connectionStatus = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://test-connectivity-5ul4qv5gj-faaezs-projects-373a7c11.vercel.app/api/test-neo4j'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'host': host,
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _connectionStatus = "✅ ${data['message']}";
        });
      } else {
        setState(() {
          _connectionStatus = "❌ ${data['message'] ?? 'Connection failed'}";
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = "❌ Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInputCard(String label, TextEditingController controller, {bool obscure = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.blueGrey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Neo4j Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputCard("Host/Url", _hostController),
              SizedBox(height: 16),
              _buildInputCard("Username", _usernameController),
              SizedBox(height: 16),
              _buildInputCard("Password", _passwordController, obscure: true),
              SizedBox(height: 30),
              Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                  ),
                  child: Text(
                    "Test Connection",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  _connectionStatus,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
