enum ComplaintStatus { submitted, queued, assigned, inProgress, resolved, closed }

enum ComplaintPriority { low, medium, high, urgent }

enum ComplaintClass {
  infrastructure,
  plumbing,
  electrical,
  it,
  disciplinary,
  general,
}

class Complaint {
  final String id;
  final String studentId;
  final String description;
  final ComplaintClass complaintClass;
  final String categoryLabel;
  final ComplaintPriority priority;
  final ComplaintStatus status;
  final DateTime submittedAt;
  final String assignedTechnicianId;

  // Location (used for dedupe + routing)
  final String block;
  final String room;

  // Attachments
  final List<String> beforeImagePaths;
  final List<String> afterImagePaths;

  // Dedup / clustering
  final String signature;
  final int similarCount;
  final List<String> reporterStudentIds;

  // AI explanations
  final double aiConfidence;
  final List<String> aiReasons;

  // Escalation (feature 17)
  final bool isEscalated;
  final DateTime? escalatedAt;

  // Feedback (feature 18)
  final int? satisfactionRating; // 1-5
  final String? feedbackComment;
  final DateTime? feedbackAt;

  Complaint({
    required this.id,
    required this.studentId,
    required this.description,
    required this.complaintClass,
    required this.categoryLabel,
    required this.priority,
    required this.status,
    required this.submittedAt,
    required this.assignedTechnicianId,
    required this.block,
    required this.room,
    this.beforeImagePaths = const [],
    this.afterImagePaths = const [],
    required this.signature,
    this.similarCount = 1,
    this.reporterStudentIds = const [],
    this.aiConfidence = 0,
    this.aiReasons = const [],
    this.isEscalated = false,
    this.escalatedAt,
    this.satisfactionRating,
    this.feedbackComment,
    this.feedbackAt,
  });

  Complaint copyWith({
    String? id,
    String? studentId,
    String? description,
    ComplaintClass? complaintClass,
    String? categoryLabel,
    ComplaintPriority? priority,
    ComplaintStatus? status,
    DateTime? submittedAt,
    String? assignedTechnicianId,
    String? block,
    String? room,
    List<String>? beforeImagePaths,
    List<String>? afterImagePaths,
    String? signature,
    int? similarCount,
    List<String>? reporterStudentIds,
    double? aiConfidence,
    List<String>? aiReasons,
    bool? isEscalated,
    DateTime? escalatedAt,
    int? satisfactionRating,
    String? feedbackComment,
    DateTime? feedbackAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      description: description ?? this.description,
      complaintClass: complaintClass ?? this.complaintClass,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      block: block ?? this.block,
      room: room ?? this.room,
      beforeImagePaths: beforeImagePaths ?? this.beforeImagePaths,
      afterImagePaths: afterImagePaths ?? this.afterImagePaths,
      signature: signature ?? this.signature,
      similarCount: similarCount ?? this.similarCount,
      reporterStudentIds: reporterStudentIds ?? this.reporterStudentIds,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiReasons: aiReasons ?? this.aiReasons,
      isEscalated: isEscalated ?? this.isEscalated,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      feedbackComment: feedbackComment ?? this.feedbackComment,
      feedbackAt: feedbackAt ?? this.feedbackAt,
    );
  }
}
