import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart'; // Optional: for proper unique IDs ('flutter pub add uuid')
import '../models/complaint.dart';
import '../models/technician.dart';
import '../models/triage_result.dart';
import '../services/ai_service.dart';

enum SubmitOutcome { assigned, queued, mergedDuplicate }

class SubmitResult {
  final SubmitOutcome outcome;
  final Complaint complaint;
  const SubmitResult(this.outcome, this.complaint);
}

class ComplaintProvider extends ChangeNotifier {
  final List<Complaint> _complaints = [];
  List<Complaint> get complaints => _complaints;

  // technicians + queue state
  final List<Technician> _technicians = const [
    Technician(
      id: 'Tech 1',
      name: 'Tech 1',
      skills: {TechnicianSkill.plumbing, TechnicianSkill.it, TechnicianSkill.general},
      maxActive: 3,
    ),
    Technician(
      id: 'Tech 2',
      name: 'Tech 2',
      skills: {TechnicianSkill.electrical, TechnicianSkill.infrastructure, TechnicianSkill.general},
      maxActive: 3,
    ),
    Technician(
      id: 'Counselor',
      name: 'Counselor',
      skills: {TechnicianSkill.disciplinary},
      maxActive: 6,
    ),
  ];

  final Map<String, List<String>> _queueByTechnician = {};

  List<Technician> get technicians => _technicians;

  List<String> queueFor(String technicianId) =>
      List.unmodifiable(_queueByTechnician[technicianId] ?? const []);

  /// Triggers a rebuild for consumers (e.g. pull-to-refresh in admin).
  void refresh() => notifyListeners();

  static const int escalationDays = 3;
  DateTime? _lastEscalationCheck;

  void checkEscalations() {
    final now = DateTime.now();
    if (_lastEscalationCheck != null &&
        now.difference(_lastEscalationCheck!).inSeconds < 60) {
      return;
    }
    _lastEscalationCheck = now;
    final cutoff = DateTime.now().subtract(Duration(days: escalationDays));
    var changed = false;
    for (var i = 0; i < _complaints.length; i++) {
      final c = _complaints[i];
      if (_isOpen(c) && !c.isEscalated && c.submittedAt.isBefore(cutoff)) {
        _complaints[i] = c.copyWith(isEscalated: true, escalatedAt: DateTime.now());
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void submitFeedback({
    required String complaintId,
    required int rating,
    String? comment,
  }) {
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx == -1) return;
    _complaints[idx] = _complaints[idx].copyWith(
      satisfactionRating: rating,
      feedbackComment: comment,
      feedbackAt: DateTime.now(),
    );
    notifyListeners();
  }

  int _activeCount(String techId) {
    return _complaints
        .where(
          (c) =>
              c.assignedTechnicianId == techId &&
              (c.status == ComplaintStatus.assigned ||
                  c.status == ComplaintStatus.inProgress),
        )
        .length;
  }

  bool _isOpen(Complaint c) =>
      c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.closed;

  String _normLoc(String s) => s.trim().toLowerCase();

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0;
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    if (union == 0) return 0;
    return intersection / union;
  }

  int _priorityRank(ComplaintPriority p) {
    return switch (p) {
      ComplaintPriority.low => 0,
      ComplaintPriority.medium => 1,
      ComplaintPriority.high => 2,
      ComplaintPriority.urgent => 3,
    };
  }

  // Stronger dedupe:
  // 1) exact signature match (class + location + canonical hits)
  // 2) near match: same class + same block/room + canonical token overlap (many students describe differently)
  Complaint? _findDuplicateOpen(String signature) {
    for (final c in _complaints) {
      if (_isOpen(c) && c.signature == signature) return c;
    }
    return null;
  }

  Complaint? _findNearDuplicateOpen({
    required ComplaintClass complaintClass,
    required String block,
    required String room,
    required String description,
  }) {
    final newTokens = AIService.canonicalTokensForDedupe(description);
    Complaint? best;
    var bestScore = 0.0;

    final b = _normLoc(block);
    final r = _normLoc(room);

    for (final c in _complaints) {
      if (!_isOpen(c)) continue;
      if (c.complaintClass != complaintClass) continue;
      if (_normLoc(c.block) != b) continue;
      if (_normLoc(c.room) != r) continue;

      final oldTokens = AIService.canonicalTokensForDedupe(c.description);
      final score = _jaccard(newTokens, oldTokens);
      if (score >= 0.35 && score >= bestScore) {
        bestScore = score;
        best = c;
      }
    }

    return best;
  }

  SubmitResult submitComplaint({
    required String studentId,
    required String description,
    required String block,
    required String room,
    List<String> beforeImagePaths = const [],
  }) {
    final triage = AIService.triage(description: description, block: block, room: room);

    final signature = triage.signature;
    final dup = _findDuplicateOpen(signature);
    if (dup != null) {
      final updated = _mergeDuplicate(
        existing: dup,
        studentId: studentId,
        beforeImagePaths: beforeImagePaths,
        triage: triage,
      );
      return _replaceComplaintAndReturn(updated);
    }

    // Fallback near-duplicate detection (same class + location, different wording).
    final nearDup = _findNearDuplicateOpen(
      complaintClass: triage.complaintClass,
      block: block,
      room: room,
      description: description,
    );
    if (nearDup != null) {
      final updated = _mergeDuplicate(
        existing: nearDup,
        studentId: studentId,
        beforeImagePaths: beforeImagePaths,
        triage: triage,
      );
      return _replaceComplaintAndReturn(updated);
    }

    final assignedTech = _assignOrQueue(triage.requiredSkills);
    final status = assignedTech.status;

    final complaint = Complaint(
      id: "CMP-${const Uuid().v4().substring(0, 4)}",
      studentId: studentId,
      description: description,
      complaintClass: triage.complaintClass,
      categoryLabel: AIService.labelFor(triage.complaintClass),
      priority: triage.priority,
      status: status == _AssignStatus.assigned
          ? ComplaintStatus.assigned
          : ComplaintStatus.queued,
      submittedAt: DateTime.now(),
      assignedTechnicianId: assignedTech.techId,
      block: block,
      room: room,
      beforeImagePaths: beforeImagePaths,
      signature: signature,
      similarCount: 1,
      reporterStudentIds: [studentId],
      aiConfidence: triage.confidence,
      aiReasons: triage.reasons,
    );

    _complaints.add(complaint);
    // if queued, replace placeholder with real complaint id
    if (status == _AssignStatus.queued) {
      final q = _queueByTechnician[assignedTech.techId];
      if (q != null) {
        final pendingIdx = q.indexOf('__PENDING__');
        if (pendingIdx != -1) q[pendingIdx] = complaint.id;
      }
    }
    notifyListeners();

    return SubmitResult(
      status == _AssignStatus.assigned ? SubmitOutcome.assigned : SubmitOutcome.queued,
      complaint,
    );
  }

  Complaint _mergeDuplicate({
    required Complaint existing,
    required String studentId,
    required List<String> beforeImagePaths,
    required TriageResult triage,
  }) {
    final reporters = {...existing.reporterStudentIds, existing.studentId, studentId}.toList();

    final mergedBefore = {
      ...existing.beforeImagePaths,
      ...beforeImagePaths,
    }.toList();

    final mergedPriorityRank = math.max(
      _priorityRank(existing.priority),
      _priorityRank(triage.priority),
    );
    final mergedPriority = switch (mergedPriorityRank) {
      3 => ComplaintPriority.urgent,
      2 => ComplaintPriority.high,
      1 => ComplaintPriority.medium,
      _ => ComplaintPriority.low,
    };

    final reasons = {...existing.aiReasons, ...triage.reasons}.toList();

    return existing.copyWith(
      similarCount: existing.similarCount + 1,
      reporterStudentIds: reporters,
      beforeImagePaths: mergedBefore,
      priority: mergedPriority,
      aiConfidence: math.max(existing.aiConfidence, triage.confidence),
      aiReasons: reasons,
    );
  }

  SubmitResult _replaceComplaintAndReturn(Complaint updated) {
    final idx = _complaints.indexWhere((c) => c.id == updated.id);
    if (idx != -1) _complaints[idx] = updated;
    notifyListeners();
    return SubmitResult(
      SubmitOutcome.mergedDuplicate,
      updated,
    );
  }

  void startWork({required String complaintId, required String technicianId}) {
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx == -1) return;
    final c = _complaints[idx];
    if (c.assignedTechnicianId != technicianId) return;
    if (c.status == ComplaintStatus.assigned) {
      _complaints[idx] = c.copyWith(status: ComplaintStatus.inProgress);
      notifyListeners();
    }
  }

  void resolveComplaint({
    required String complaintId,
    required String technicianId,
    List<String> afterImagePaths = const [],
  }) {
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx == -1) return;
    final c = _complaints[idx];
    if (c.assignedTechnicianId != technicianId) return;
    _complaints[idx] = c.copyWith(
      status: ComplaintStatus.resolved,
      afterImagePaths: [...c.afterImagePaths, ...afterImagePaths],
    );
    _promoteFromQueue(technicianId);
    notifyListeners();
  }

  void closeComplaint({required String complaintId}) {
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx == -1) return;
    _complaints[idx] = _complaints[idx].copyWith(status: ComplaintStatus.closed);
    notifyListeners();
  }

  void assignTechnician({required String complaintId, required String technician}) {
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx == -1) return;
    final current = _complaints[idx];
    final updated = current.copyWith(
      assignedTechnicianId: technician,
      status: technician == 'Unassigned'
          ? ComplaintStatus.submitted
          : ComplaintStatus.assigned,
    );
    _complaints[idx] = updated;
    notifyListeners();
  }

  void updateStatus({required String complaintId, required ComplaintStatus status}) {
    final idx = _complaints.indexWhere((c) => c.id == complaintId);
    if (idx == -1) return;
    _complaints[idx] = _complaints[idx].copyWith(status: status);
    notifyListeners();
  }

  _AssignResult _assignOrQueue(Set<TechnicianSkill> required) {
    final eligible = _technicians
        .where((t) => t.skills.intersection(required).isNotEmpty)
        .toList();
    if (eligible.isEmpty) {
      return const _AssignResult('Tech 1', _AssignStatus.queued);
    }

    eligible.sort((a, b) {
      final la = _activeCount(a.id) + queueFor(a.id).length;
      final lb = _activeCount(b.id) + queueFor(b.id).length;
      return la.compareTo(lb);
    });

    // prefer someone with capacity
    for (final t in eligible) {
      if (_activeCount(t.id) < t.maxActive) {
        return _AssignResult(t.id, _AssignStatus.assigned);
      }
    }

    // no capacity: queue to least loaded eligible
    final t = eligible.first;
    final q = _queueByTechnician.putIfAbsent(t.id, () => []);
    // placeholder id will be added after complaint creation; we queue by signature later.
    // We'll push a temp marker for now; replaced by complaint id after add.
    q.add('__PENDING__');
    return _AssignResult(t.id, _AssignStatus.queued);
  }

  void _promoteFromQueue(String technicianId) {
    final tech = _technicians.firstWhere(
      (t) => t.id == technicianId,
      orElse: () => const Technician(id: 'x', name: 'x', skills: {}, maxActive: 0),
    );
    if (tech.maxActive == 0) return;
    if (_activeCount(technicianId) >= tech.maxActive) return;

    final q = _queueByTechnician[technicianId];
    if (q == null || q.isEmpty) return;

    // remove placeholders and keep only real complaint ids that still exist and are queued
    q.removeWhere((id) => id == '__PENDING__');
    if (q.isEmpty) return;

    final nextId = q.removeAt(0);
    final idx = _complaints.indexWhere((c) => c.id == nextId);
    if (idx == -1) return;
    final c = _complaints[idx];
    if (c.status != ComplaintStatus.queued) return;
    _complaints[idx] = c.copyWith(status: ComplaintStatus.assigned);
  }
}

enum _AssignStatus { assigned, queued }

class _AssignResult {
  final String techId;
  final _AssignStatus status;
  const _AssignResult(this.techId, this.status);
}
