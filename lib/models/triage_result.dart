import 'complaint.dart';
import 'technician.dart';

class TriageResult {
  final ComplaintClass complaintClass;
  final ComplaintPriority priority;
  final double urgencyScore; // 0..1
  final double confidence; // 0..1
  final List<String> reasons;
  final Set<TechnicianSkill> requiredSkills;
  final String signature; // normalized text+location signature for dedupe

  const TriageResult({
    required this.complaintClass,
    required this.priority,
    required this.urgencyScore,
    required this.confidence,
    required this.reasons,
    required this.requiredSkills,
    required this.signature,
  });
}

