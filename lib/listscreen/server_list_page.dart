import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Server {
  final String name;

  Server({required this.name});

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      name: json['name'],
    );
  }
}

class ServerListPage extends StatefulWidget {
  const ServerListPage({Key? key}) : super(key: key);

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  List<Server> servers = [];

  Future<void> fetchServers() async {
    final response = await http.post(
      Uri.parse('https://api-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graphql'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": """
          query {
            allServers {
              name
            }
          }
        """
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final serverList = data['data']['allServers'] as List;
      setState(() {
        servers = serverList.map((s) => Server.fromJson(s)).toList();
      });
    } else {
      throw Exception("Failed to load servers");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchServers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servers"),
        backgroundColor: Colors.blueAccent,
      ),
      body: servers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns
          crossAxisSpacing: 10, // Spacing between columns
          mainAxisSpacing: 10, // Spacing between rows
          childAspectRatio: 1.0, // Equal width and height for grid items
        ),
        itemCount: servers.length,
        itemBuilder: (context, index) {
          final server = servers[index];
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
                      Icons.computer, // Common server icon
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      server.name, // Server name
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
