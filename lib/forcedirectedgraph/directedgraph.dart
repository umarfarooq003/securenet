import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';

class Neo4jForceGraphPage extends StatefulWidget {
  @override
  _Neo4jForceGraphPageState createState() => _Neo4jForceGraphPageState();
}

class _Neo4jForceGraphPageState extends State<Neo4jForceGraphPage> {
  final controller = ForceDirectedGraphController<String>();
  bool isLoading = true;
  String? errorMsg;
  List<dynamic> graphData = [];
  Map<String, String> nodeInfo = {};

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  Future<void> fetchGraphData() async {
    const url =
        'https://new-folder-3-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graph';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        graphData = body;

        final nodes = <String>{};
        final edges = <Map<String, String>>[];

        for (var entry in body) {
          String? sourceName = entry["n"]?["name"];
          String? targetName = entry["m"]?["name"];
          String label = entry["r"] ?? '';

          if (sourceName != null && sourceName.isNotEmpty) nodes.add(sourceName);
          if (targetName != null && targetName.isNotEmpty) nodes.add(targetName);

          if (sourceName != null &&
              targetName != null &&
              sourceName.isNotEmpty &&
              targetName.isNotEmpty) {
            edges.add({
              'source': sourceName,
              'target': targetName,
              'label': label,
            });
          }
        }

        controller.graph.nodes.clear();
        controller.graph.edges.clear();

        for (var nodeId in nodes) {
          controller.addNode(nodeId);
        }

        for (var edge in edges) {
          controller.addEdgeByData(edge['source']!, edge['target']!);
        }

        setState(() {
          isLoading = false;
          errorMsg = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMsg = 'Error ${response.statusCode}: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Exception: $e';
      });
    }
  }

  Color getNodeColor(String nodeName, bool isSuspected) {
    final lower = nodeName.toLowerCase();

    if (isSuspected) return Colors.red;
    if (lower.contains("router")) return Colors.blue;
    if (lower.contains("switch")) return Colors.green;
    if (lower.contains("endpoint")) return Colors.orange;
    if (lower.contains("server")) return Colors.grey;
    if (lower.contains("loadbalancer") ||
        (lower.contains("load") && lower.contains("balancer"))) return Colors.teal;

    return Colors.purple;
  }

  String getNodeInfo(Map<String, dynamic> node) {
    String info = "Name: ${node["name"] ?? 'Unknown'}\n";
    if (node["ip"] != null) info += "IP: ${node["ip"]}\n";
    if (node["mac"] != null) info += "MAC: ${node["mac"]}\n";
    if (node["ipAddress"] != null) info += "Device IP: ${node["ipAddress"]}\n";
    if (node["macAddress"] != null) info += "Device MAC: ${node["macAddress"]}\n";
    if (node["suspected"] != null) info += "Suspected: ${node["suspected"] ? 'Yes' : 'No'}\n";
    return info;
  }

  Widget legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Neo4j Graph'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh,color: Colors.white),
            tooltip: "Refresh Graph",
            onPressed: fetchGraphData,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(child: Text(errorMsg!))
          : Column(
        children: [
          // 🔝 Graph
          Expanded(
            child: ForceDirectedGraphWidget<String>(
              controller: controller,
              nodesBuilder: (context, nodeData) {
                var selectedNode = graphData.firstWhere(
                      (element) =>
                  element["n"]?["name"] == nodeData ||
                      element["m"]?["name"] == nodeData,
                  orElse: () => null,
                );

                Map<String, dynamic> node =
                selectedNode?["n"]?["name"] == nodeData
                    ? selectedNode["n"]
                    : selectedNode?["m"];

                if (node != null) {
                  bool isSuspected = node["suspected"] ?? false;
                  Color nodeColor = getNodeColor(nodeData, isSuspected);
                  bool isSelected = nodeInfo.containsKey(nodeData);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        nodeInfo.clear();
                        nodeInfo[nodeData] = getNodeInfo(node);
                      });

                      Future.delayed(Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            nodeInfo.remove(nodeData);
                          });
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.all(6),
                            margin: EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black54),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(maxWidth: 120),
                            child: Text(
                              nodeInfo[nodeData] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: nodeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container();
              },
              edgesBuilder: (context, a, b, distance) {
                return Container(
                  width: distance > 10 ? distance : 10,
                  height: 2,
                  color: Colors.grey,
                );
              },
            ),
          ),

          // 👇 Legend at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 10,
              children: [
                legendItem('Routers', Colors.blue),
                legendItem('Switches', Colors.green),
                legendItem('Endpoints', Colors.orange),
                legendItem('Servers', Colors.grey),
                legendItem('LoadBalancers', Colors.teal),
                legendItem('Suspected', Colors.red),
                legendItem('Others', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
