import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import '../charts/charts.dart';
import '../forcedirectedgraph/directedgraph.dart';
import '../listscreen/listdeice.dart';
import '../listscreen/server_list_page.dart';
import '../listscreen/switch_list_page.dart';
import '../settings_screen.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String email;

  HomePage({required this.username, required this.email});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(), // Real data dashboard screen
    GraphVisualizationScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _saveProfileImage(pickedFile.path);
    }
  }

  Future<void> _saveProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      prefs.setString('profile_image_${user.uid}', path);
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final path = prefs.getString('profile_image_${user.uid}');
      if (path != null) {
        setState(() {
          _image = File(path);
        });
      }
    }
  }

  void _onBottomNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Network Vulnerability Assessment using Graph Theory"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              accountName: Text(widget.username,
                  style: TextStyle(fontSize: 18)),
              accountEmail: Text(widget.email, style: TextStyle(fontSize: 14)),
              currentAccountPicture: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : AssetImage("assets/default_profile.png")
                  as ImageProvider,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text("Home"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomePage(
                            username: widget.username, email: widget.email)));
              },
            ),
            ListTile(
              leading: Icon(Icons.device_hub),
              title: Text("Neo4j Visualization"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Neo4jForceGraphPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.computer),
              title: Text("List Device"),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => DeviceListPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud),
              title: Text("List Servers"),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ServerListPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.switch_camera),
              title: Text("List NetworkSwitches"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SwitchListPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.switch_camera),
              title: Text("Charts"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NetworkCharts()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => LoginScreen()));
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavBarTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.graphic_eq), label: 'Visualization'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ---------------------- HomeScreen with Real Counts ------------------------

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> counts = {
    "Routers": 0,
    "Switches": 0,
    "Servers": 0,
    "End Points": 0,
    "Suspected": 0,
    "Infected": 0,
    "Recovered": 0,
    "Vulnerabilities": 0,
  };

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    final url =
        'https://new-folder-3-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graph';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // Use the body directly if it is a List; otherwise, try to use body['data']
        final data = body is List ? body : (body['data'] ?? []);

        // Set to track processed IDs to avoid duplicates
        Set<String> processedIds = {};

        // Initialize counts map with integer values
        Map<String, int> tempCounts = {
          "Routers": 0,
          "Switches": 0,
          "Servers": 0,
          "End Points": 0,
          "Suspected": 0,
          "Infected": 0,
          "Recovered": 0,
          "Vulnerabilities": 0,
        };

        // Iterate through the nodes in the fetched data
        for (var item in data) {
          // Loop through node pairs ('n' and 'm')
          for (var nodeKey in ['n', 'm']) {
            final node = item[nodeKey];
            if (node == null) continue;

            // Get node id and label/type. Since your sample data may not include an "id", use the "name" as fallback.
            final id = (node['id'] ?? node['name'])?.toString();
            if (id == null || processedIds.contains(id)) continue;

            // Mark the id as processed
            processedIds.add(id);

            // Ensure the label/type is a string:
            final label = (node['label'] ?? node['type'] ?? node['name'] ?? '')
                .toString()
                .toLowerCase();

            // Safe count increment based on label
            if (label.contains('router')) {
              tempCounts['Routers'] = (tempCounts['Routers'] ?? 0) + 1;
            } else if (label.contains('switch')) {
              tempCounts['Switches'] = (tempCounts['Switches'] ?? 0) + 1;
            } else if (label.contains('server')) {
              tempCounts['Servers'] = (tempCounts['Servers'] ?? 0) + 1;
            } else if (label.contains('endpoint') || label.contains('device')) {
              tempCounts['End Points'] =
                  (tempCounts['End Points'] ?? 0) + 1;
            } else if (label.contains('suspected')) {
              tempCounts['Suspected'] =
                  (tempCounts['Suspected'] ?? 0) + 1;
            } else if (label.contains('infected')) {
              tempCounts['Infected'] =
                  (tempCounts['Infected'] ?? 0) + 1;
            } else if (label.contains('recovered')) {
              tempCounts['Recovered'] =
                  (tempCounts['Recovered'] ?? 0) + 1;
            } else if (label.contains('vulnerability')) {
              tempCounts['Vulnerabilities'] =
                  (tempCounts['Vulnerabilities'] ?? 0) + 1;
            }
          }
        }

        setState(() {
          counts = Map.from(tempCounts); // Update state with the counts
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Error ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Exception: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homePage =
    context.findAncestorWidgetOfExactType<HomePage>();
    final String username = homePage?.username ?? "Guest";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dashboard",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Welcome, $username",
              style: TextStyle(
                  fontSize: 18, color: Colors.grey[700])),
          SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: counts.entries.map((e) {
                return _buildGridItem(
                    getIconForLabel(e.key),
                    e.key,
                    e.value.toString());
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData getIconForLabel(String label) {
    switch (label) {
      case "Routers":
        return Icons.router;
      case "Switches":
        return Icons.switch_camera;
      case "Servers":
        return Icons.cloud;
      case "End Points":
        return Icons.computer;
      case "Suspected":
        return Icons.warning;
      case "Infected":
        return Icons.bug_report;
      case "Recovered":
        return Icons.healing;
      case "Vulnerabilities":
        return Icons.security;
      default:
        return Icons.device_unknown;
    }
  }

  Widget _buildGridItem(IconData icon, String title, String count) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.blue),
          SizedBox(height: 10),
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text("Total: $count",
              style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// ------------------------ Graph Visualization Screen ------------------------

class GraphVisualizationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildGridItem(
              context,
              icon: Icons.graphic_eq,
              label: 'Neo4j Visualization',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Neo4jForceGraphPage())),
            ),
            _buildGridItem(
              context,
              icon: Icons.devices,
              label: 'Devices',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DeviceListPage())),
            ),
            _buildGridItem(
              context,
              icon: Icons.storage,
              label: 'Servers',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ServerListPage())),
            ),
            _buildGridItem(
              context,
              icon: Icons.swap_calls,
              label: 'Switches',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SwitchListPage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
