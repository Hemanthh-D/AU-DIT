import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/session/session_provider.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_spacing.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';

class ComplaintStatusScreen extends StatefulWidget {
  const ComplaintStatusScreen({super.key});

  @override
  State<ComplaintStatusScreen> createState() => _ComplaintStatusScreenState();
}

class _ComplaintStatusScreenState extends State<ComplaintStatusScreen> {
  String? _selectedComplaintId;

  int _stepForStatus(ComplaintStatus status) {
    return switch (status) {
      ComplaintStatus.submitted => 0,
      ComplaintStatus.queued => 1,
      ComplaintStatus.assigned => 1,
      ComplaintStatus.inProgress => 2,
      ComplaintStatus.resolved => 3,
      ComplaintStatus.closed => 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final provider = context.watch<ComplaintProvider>();
    final scheme = Theme.of(context).colorScheme;
    final items = provider.complaints
        .where((c) => c.studentId == session.studentId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Complaint Status")),
        body: Center(
          child: Text(
            "No complaints yet.\nSubmit a new report to track status here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final complaint = items.firstWhere(
      (c) => c.id == _selectedComplaintId,
      orElse: () => items.first,
    );
    final currentStep = _stepForStatus(complaint.status);
    final step1Title = complaint.status == ComplaintStatus.queued
        ? "Queued for technician"
        : "Assigned to technician";
    final step1Subtitle = complaint.status == ComplaintStatus.queued
        ? "Waiting for capacity — will auto-promote to Assigned."
        : (complaint.assignedTechnicianId.isEmpty || complaint.assignedTechnicianId == 'Unassigned'
            ? "Awaiting admin assignment"
            : "${complaint.assignedTechnicianId} assigned");

    final steps = [
      {
        "title": "Report Submitted",
        "subtitle": "AI classified as '${complaint.categoryLabel}'.",
      },
      {
        "title": step1Title,
        "subtitle": step1Subtitle,
      },
      {"title": "Work In Progress", "subtitle": "Technician is working on it"},
      {"title": "Resolved", "subtitle": "Marked as resolved"},
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.track_changes_rounded, color: AppColors.info, size: 20),
            ),
            const SizedBox(width: 12),
            Text("Ticket #${complaint.id}", style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top selector: latest 5 complaints
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.indigoTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_outlined,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Latest complaint",
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            "${complaint.id} • ${complaint.categoryLabel}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: "Select ticket",
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onSelected: (id) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedComplaintId = id);
                      },
                      itemBuilder: (context) {
                        return items.take(5).map((c) {
                          return PopupMenuItem<String>(
                            value: c.id,
                            child: Text("${c.id} • ${c.categoryLabel}"),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              complaint.description,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Pill(
                  icon: Icons.priority_high,
                  text: complaint.priority.name.toUpperCase(),
                  background: AppColors.pinkTint,
                  color: AppColors.danger,
                ),
                _Pill(
                  icon: Icons.sync_alt,
                  text: complaint.status.name,
                  background: scheme.surfaceContainerHighest,
                  color: scheme.onSurface,
                ),
                _Pill(
                  icon: Icons.engineering_outlined,
                  text: complaint.assignedTechnicianId.isEmpty || complaint.assignedTechnicianId == 'Unassigned'
                      ? "Unassigned"
                      : complaint.assignedTechnicianId,
                  background: scheme.surfaceContainerHighest,
                  color: scheme.onSurface,
                ),
              ],
            ),
            if ((complaint.status == ComplaintStatus.resolved || complaint.status == ComplaintStatus.closed) &&
                complaint.satisfactionRating == null) ...[
              _FeedbackSection(complaintId: complaint.id),
              const SizedBox(height: AppSpacing.xl),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              "Status timeline",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  bool isCompleted = index <= currentStep;
                  bool isLast = index == steps.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline Graphic
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color: isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outlineVariant,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 50,
                              color: isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Text Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                steps[index]["title"]!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                steps[index]["subtitle"]!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isCompleted
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackSection extends StatefulWidget {
  const _FeedbackSection({required this.complaintId});
  final String complaintId;

  @override
  State<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<_FeedbackSection> {
  int? _selectedRating;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'How satisfied are you with the resolution?',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final rating = i + 1;
              final selected = _selectedRating == rating;
              return IconButton(
                onPressed: () => setState(() => _selectedRating = rating),
                icon: Icon(
                  rating <= (_selectedRating ?? 0) ? Icons.star : Icons.star_border,
                  color: selected ? Colors.amber : scheme.onSurfaceVariant,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Optional feedback...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedRating == null
                  ? null
                  : () {
                      context.read<ComplaintProvider>().submitFeedback(
                            complaintId: widget.complaintId,
                            rating: _selectedRating!,
                            comment: _commentController.text.trim().isEmpty
                                ? null
                                : _commentController.text.trim(),
                          );
                      setState(() {});
                    },
              child: const Text('Submit feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
