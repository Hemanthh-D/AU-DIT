import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Optional: for proper unique IDs ('flutter pub add uuid')
import '../models/complaint.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  List<Complaint> get complaints => _complaints;

  // This function strengthens your AI Routing
  Map<String, String> _strongAIService(String text) {
    String t = text.toLowerCase();

    // 1. ADVANCED RAGGING/DISCIPLINARY CHECK
    // If these keywords appear, they are sent to the AI Counselor immediately.
    if (t.contains("ragging") ||
        t.contains("harassment") ||
        t.contains("bully")) {
      return {
        "category": "Disciplinary Incident",
        "priority": "urgent",
        "reason": "AI flagged critical keyword",
        "assignedTo": "Dr. Anjali (Counselor)",
      };
    }

    // 2. NETWORK ISSUES
    if (t.contains("wifi") || t.contains("internet")) {
      return {
        "category": "IT Support",
        "priority": "high",
        "reason": "AI detected network keyword",
        "assignedTo": "Network Dept Head",
      };
    }

    // 3. FACILITY MAINTAINENCE (Default)
    return {
      "category": "Facility Maintenance",
      "priority": "low",
      "reason": "AI mapped to general maintenance",
      "assignedTo": "Unassigned", // Phase 3: Admin must assign
    };
  }

  // A direct implementation of your Duplicate Check logic
  bool isDuplicateRequest(String newDescription) {
    for (var c in _complaints) {
      if (c.description.toLowerCase().replaceAll(' ', '') ==
          newDescription.toLowerCase().replaceAll(' ', '')) {
        return true;
      }
    }
    return false;
  }

  // Pre-analyzes before adding
  void addComplaint(String studentId, String description) {
    var aiResult = _strongAIService(description);

    // Check for duplicates before finalizing submission
    if (isDuplicateRequest(description)) {
      // In a real app, you would show a warning box in the UI first.
      // We will handle this in the next step.
    }

    // Map string values from AI logic to proper data types
    ComplaintPriority mappedPriority = ComplaintPriority.values.byName(
      aiResult["priority"]!,
    );

    final newComplaint = Complaint(
      id: "CMP-${const Uuid().v4().substring(0, 4)}", // Simplified unique ID
      studentId: studentId,
      description: description,
      category: aiResult["category"]!,
      priority: mappedPriority,
      status: ComplaintStatus.submitted,
      submittedAt: DateTime.now(),
      assignedTechnicianId: aiResult["assignedTo"]!,
    );

    _complaints.add(newComplaint);
    notifyListeners();
  }
}
