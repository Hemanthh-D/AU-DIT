enum NotificationType {
  technicianAssigned,
  workStarted,
  resolved,
  closed,
  escalated,
}

class AppNotification {
  final String id;
  final String complaintId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? studentId;
  final String? technicianId; // When set, notification is for this tech/counselor

  const AppNotification({
    required this.id,
    required this.complaintId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.studentId,
    this.technicianId,
  });

  AppNotification copyWith({
    String? id,
    String? complaintId,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? read,
    String? studentId,
    String? technicianId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      complaintId: complaintId ?? this.complaintId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      studentId: studentId ?? this.studentId,
      technicianId: technicianId ?? this.technicianId,
    );
  }
}
