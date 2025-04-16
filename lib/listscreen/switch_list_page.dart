import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkSwitch {
  final String name;

  NetworkSwitch({required this.name});

  factory NetworkSwitch.fromJson(Map<String, dynamic> json) {
    return NetworkSwitch(
      name: json['name'],
    );
  }
}

class SwitchListPage extends StatefulWidget {
  const SwitchListPage({Key? key}) : super(key: key);

  @override
  State<SwitchListPage> createState() => _SwitchListPageState();
}

class _SwitchListPageState extends State<SwitchListPage> {
  List<NetworkSwitch> switches = [];

  Future<void> fetchSwitches() async {
    final response = await http.post(
      Uri.parse('https://api-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graphql'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": """
          query {
            allSwitches {
              name
              mac
            }
          }
        """
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final switchList = data['data']['allSwitches'] as List;
      setState(() {
        switches = switchList.map((s) => NetworkSwitch.fromJson(s)).toList();
      });
    } else {
      throw Exception("Failed to load switches");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSwitches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Switches"),
        backgroundColor: Colors.blueAccent,
      ),
      body: switches.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns
          crossAxisSpacing: 10, // Spacing between columns
          mainAxisSpacing: 10, // Spacing between rows
          childAspectRatio: 1.0, // Equal width and height for grid items
        ),
        itemCount: switches.length,
        itemBuilder: (context, index) {
          final networkSwitch = switches[index];
          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              onTap: () {
                // You can add any action when tapped on the card here
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.device_hub, // Common switch icon
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      networkSwitch.name, // Switch name
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
