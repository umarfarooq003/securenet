import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiskJsonPage extends StatefulWidget {
  const RiskJsonPage({Key? key}) : super(key: key);

  @override
  _RiskJsonPageState createState() => _RiskJsonPageState();
}

class _RiskJsonPageState extends State<RiskJsonPage> {
  bool isLoading = true;
  String? errorMsg;
  List<dynamic>? indirectRisks;

  @override
  void initState() {
    super.initState();
    fetchJsonData();
  }

  Future<void> fetchJsonData() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graphql'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": """
            query {
              indirectRisks {
                source
                rel1Type
                mediator
                rel2Type
                target
                riskType
              }
            }
          """
        }),
      );

      final decoded = jsonDecode(response.body);

      if (decoded['errors'] != null) {
        setState(() {
          isLoading = false;
          errorMsg = "GraphQL Error: ${decoded['errors']}";
        });
      } else {
        setState(() {
          isLoading = false;
          indirectRisks = decoded['data']['indirectRisks'];
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMsg = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Indirect Risks Table"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(child: Text(errorMsg!))
          : LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          return InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.8,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(20),
            child: SizedBox(
              width: screenWidth,
              height: screenHeight - kToolbarHeight - 24, // Adjust for AppBar height
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ),
                    border: TableBorder.all(color: Theme.of(context).dividerColor),
                    columnSpacing: 24,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Source')),
                      DataColumn(label: Text('Rel1 Type')),
                      DataColumn(label: Text('Mediator')),
                      DataColumn(label: Text('Rel2 Type')),
                      DataColumn(label: Text('Target')),
                      DataColumn(label: Text('Risk Type')),
                    ],
                    rows: indirectRisks!.map((risk) {
                      return DataRow(cells: [
                        DataCell(Text(risk['source'] ?? '')),
                        DataCell(Text(risk['rel1Type'] ?? '')),
                        DataCell(Text(risk['mediator'] ?? '')),
                        DataCell(Text(risk['rel2Type'] ?? '')),
                        DataCell(Text(risk['target'] ?? '')),
                        DataCell(Text(risk['riskType'] ?? '')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),



      floatingActionButton: FloatingActionButton(
        onPressed: fetchJsonData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
