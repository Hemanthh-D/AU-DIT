enum ComplaintStatus { submitted, assigned, inProgress, resolved }

enum ComplaintPriority { low, medium, high, urgent }

class Complaint {
  final String id;
  final String studentId;
  final String description;
  final String category;
  ComplaintPriority priority;
  ComplaintStatus status;
  final DateTime submittedAt;
  String assignedTechnicianId;
  List<String> imageUrls; // For Phase 4

  Complaint({
    required this.id,
    required this.studentId,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.submittedAt,
    this.assignedTechnicianId = "",
    this.imageUrls = const [],
  });
}
