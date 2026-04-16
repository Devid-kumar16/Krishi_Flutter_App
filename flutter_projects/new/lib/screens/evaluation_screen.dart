import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/evaluation_service.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  late Future<Map<String, dynamic>> metricsFuture;

  @override
  void initState() {
    super.initState();
    metricsFuture = EvaluationService.getMetrics();
  }

  void refreshData() {
    setState(() {
      metricsFuture = EvaluationService.getMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Evaluation Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshData,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: metricsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Error loading data"));
            }

            final data = snapshot.data as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildChart(data),
                  const SizedBox(height: 20),

                  _buildMetric("Accuracy", data['accuracy']),
                  _buildMetric("Precision", data['precision']),
                  _buildMetric("Recall", data['recall']),
                  _buildMetric("F1 Score", data['f1_score']),

                  const SizedBox(height: 20),
                  _buildConfusionMatrix(data['confusion_matrix']),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 📊 BAR CHART
  Widget _buildChart(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              titlesData: FlTitlesData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: [
                _bar("Acc", data['accuracy'], 0),
                _bar("Pre", data['precision'], 1),
                _bar("Rec", data['recall'], 2),
                _bar("F1", data['f1_score'], 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(String label, double value, int x) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 18,
        )
      ],
    );
  }

  // 📊 METRIC CARD WITH LABEL
  Widget _buildMetric(String title, dynamic value) {
    double val = (value is int) ? value.toDouble() : value;

    String label;
    if (val > 85) {
      label = "Excellent";
    } else if (val > 60) {
      label = "Good";
    } else {
      label = "Poor";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text("Performance: $label"),
        trailing: Text("${val.toStringAsFixed(1)}%"),
      ),
    );
  }

  // 📋 CONFUSION MATRIX
  Widget _buildConfusionMatrix(List matrix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Confusion Matrix",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Table(
              border: TableBorder.all(),
              children: matrix.map<TableRow>((row) {
                return TableRow(
                  children: row.map<Widget>((cell) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Center(child: Text(cell.toString())),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}