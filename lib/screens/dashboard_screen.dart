import 'package:flutter/material.dart';
import 'submit_complaint.dart';
import 'complaint_status.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Portal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildActionCard(
              context,
              "New Report",
              "Submit a smart complaint",
              "NR",
              const Color(0xFFFFE4E6), // Pastel Pink
              Colors.redAccent,
              const SubmitComplaintScreen(),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              context,
              "Track Status",
              "View your active requests",
              "TS",
              const Color(0xFFE0E7FF), // Pastel Indigo
              Colors.indigo,
              const ComplaintStatusScreen(),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              context,
              "Campus Guidelines",
              "Read rules and FAQs",
              "CG",
              const Color(0xFFDCFCE7), // Pastel Green
              Colors.green,
              null, // Add screen later
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    String iconText,
    Color badgeBg,
    Color badgeText,
    Widget? targetScreen,
  ) {
    return GestureDetector(
      onTap: () {
        if (targetScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
          );
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    iconText,
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
