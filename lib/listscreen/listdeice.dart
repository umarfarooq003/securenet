import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Device {
  final String name;
  final String ip;
  final String mac;

  Device({required this.name, required this.ip, required this.mac});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      name: json['name'],
      ip: json['ipAddress'],
      mac: json['macAddress'],
    );
  }
}

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({Key? key}) : super(key: key);

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<Device> devices = [];

  Future<void> fetchDevices() async {
    final response = await http.post(
      Uri.parse('https://api-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graphql'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "query": """
          query {
            allDevices {
              name
              ipAddress
              macAddress
            }
          }
        """
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final deviceList = data['data']['allDevices'] as List;
      setState(() {
        devices = deviceList.map((d) => Device.fromJson(d)).toList();
      });
    } else {
      throw Exception("Failed to load devices");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Devices"),
        backgroundColor: Colors.blueAccent,
      ),
      body: devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3 / 2, // Width / Height ratio
          ),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "IP: ${device.ip}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "MAC: ${device.mac}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
