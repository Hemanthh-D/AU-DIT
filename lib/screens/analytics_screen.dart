import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Campus Insights")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat Grid
            Row(
              children: [
                _buildStatCard(
                  "Total",
                  "142",
                  Icons.receipt_long,
                  const Color(0xFFE0E7FF),
                  Colors.indigo,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "Resolved",
                  "98",
                  Icons.check_circle_outline,
                  const Color(0xFFDCFCE7),
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildStatCard(
                  "Pending",
                  "31",
                  Icons.hourglass_empty,
                  const Color(0xFFFEF3C7),
                  Colors.orange,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "Urgent",
                  "13",
                  Icons.warning_amber,
                  const Color(0xFFFFE4E6),
                  Colors.redAccent,
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              "Category Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildBar("Infrastructure", 65, Colors.blue),
                    _buildBar("IT & Network", 45, Colors.purple),
                    _buildBar("Hostel/Mess", 80, Colors.orange),
                    _buildBar("Disciplinary", 10, Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 15),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("$value", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
