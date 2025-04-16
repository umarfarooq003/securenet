import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkCharts extends StatefulWidget {
  const NetworkCharts({super.key});

  @override
  State<NetworkCharts> createState() => _NetworkChartsState();
}

class _NetworkChartsState extends State<NetworkCharts> {
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

  final List<Color> chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.cyan,
    Colors.brown,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    const url =
        'https://new-folder-3-faeezusmani2002-gmailcom-faaezs-projects-373a7c11.vercel.app/graph';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body is List ? body : (body['data'] ?? []);
        Set<String> processedIds = {};

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

        for (var item in data) {
          for (var nodeKey in ['n', 'm']) {
            final node = item[nodeKey];
            if (node == null) continue;

            final id = (node['id'] ?? node['name'])?.toString();
            if (id == null || processedIds.contains(id)) continue;

            processedIds.add(id);

            final label = (node['label'] ?? node['type'] ?? node['name'] ?? '')
                .toString()
                .toLowerCase();

            if (label.contains('router')) {
              tempCounts.update('Routers', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('switch')) {
              tempCounts.update('Switches', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('server')) {
              tempCounts.update('Servers', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('endpoint') || label.contains('device')) {
              tempCounts.update('End Points', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('suspected')) {
              tempCounts.update('Suspected', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('infected')) {
              tempCounts.update('Infected', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('recovered')) {
              tempCounts.update('Recovered', (v) => v + 1, ifAbsent: () => 1);
            } else if (label.contains('vulnerability')) {
              tempCounts.update('Vulnerabilities', (v) => v + 1, ifAbsent: () => 1);
            }
          }
        }

        setState(() {
          counts = Map.from(tempCounts);
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

  List<PieChartSectionData> getPieChartData(List<MapEntry<String, int>> entries) {
    final total = entries.fold(0, (a, b) => a + b.value);

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percent = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percent.toStringAsFixed(1)}%',
        color: chartColors[index % chartColors.length],
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<BarChartGroupData> getBarChartData(List<MapEntry<String, int>> entries) {
    return List.generate(entries.length, (i) {
      final entry = entries[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: chartColors[i % chartColors.length],
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.where((e) => e.value > 0).toList();

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text(error!)));
    }

    final maxCount = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);
    final roundedMaxY = (maxCount + 5 - (maxCount % 5)).toDouble(); // round to nearest 5
    final interval = (roundedMaxY / 5).ceilToDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Charts'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Network Distribution (Pie Chart)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: getPieChartData(entries),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(entries.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: chartColors[i % chartColors.length],
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    Text(entries[i].key),
                    const SizedBox(width: 12),
                  ],
                );
              }),
            ),
            const SizedBox(height: 40),
            const Text(
              "Bar Chart",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: getBarChartData(entries),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: roundedMaxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    horizontalInterval: interval,
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${entries[groupIndex].key}\n${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= entries.length) {
                            return const SizedBox();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              entries[value.toInt()].key,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
