import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_provider.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_messenger.dart';
import '../core/ui/app_spacing.dart';
import '../models/app_notification.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';
import '../providers/notification_provider.dart';

class TechnicianPanel extends StatefulWidget {
  const TechnicianPanel({super.key});

  @override
  State<TechnicianPanel> createState() => _TechnicianPanelState();
}

class _TechnicianPanelState extends State<TechnicianPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintProvider>().checkEscalations();
    });
  }

  void _showProfile(BuildContext context) {
    final session = context.read<SessionProvider>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                session.email ?? "Technician",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Technician ID: ${session.technicianId}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                value: session.darkMode,
                onChanged: session.setDarkMode,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text("Dark mode"),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text("Log out"),
                onTap: () {
                  session.logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final provider = context.watch<ComplaintProvider>();
    final techId = session.technicianId;
    final assigned =
        provider.complaints
            .where(
              (c) =>
                  c.assignedTechnicianId == techId &&
                  (c.status == ComplaintStatus.assigned ||
                      c.status == ComplaintStatus.inProgress),
            )
            .toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    final queuedIds = provider.queueFor(techId);
    final queued = queuedIds
        .map((id) {
          try {
            return provider.complaints.firstWhere((c) => c.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Complaint>()
        .toList();

    final resolved =
        provider.complaints
            .where(
              (c) =>
                  c.assignedTechnicianId == techId &&
                  c.status == ComplaintStatus.resolved,
            )
            .toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    final initialIndex = assigned.isNotEmpty
        ? 0
        : queued.isNotEmpty
        ? 1
        : resolved.isNotEmpty
        ? 2
        : 0;

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 4,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      techId == 'Counselor' ? 'Counselor Portal' : 'Technician',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${assigned.length} active • ${queued.length} queued • ${resolved.length} resolved",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _TechNotificationButton(techId: techId),
            IconButton(
              tooltip: "Profile",
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => _showProfile(context),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: "Assigned (${assigned.length})"),
              Tab(text: "Queue (${queued.length})"),
              Tab(text: "Resolved (${resolved.length})"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TaskList(tasks: assigned, techId: techId),
            _QueueList(queued: queued),
            _ResolvedList(resolved: resolved),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.techId});
  final List<Complaint> tasks;
  final String techId;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.indigoTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.info,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "No active tasks",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Complaints assigned to you will appear here",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ComplaintCard(
            complaint: task,
            trailing: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (task.status == ComplaintStatus.assigned) {
                  context.read<ComplaintProvider>().startWork(
                    complaintId: task.id,
                    technicianId: techId,
                  );
                  _notifyStudent(
                    context,
                    task.studentId,
                    task.id,
                    NotificationType.workStarted,
                    'Work started',
                    '$techId has started working on your complaint ${task.id}.',
                  );
                  AppMessenger.showSnack("Started work on ${task.id}");
                } else {
                  _resolveFlow(context, task, techId);
                }
              },
              child: Text(
                task.status == ComplaintStatus.assigned ? 'Start' : 'Resolve',
              ),
            ),
            onTap: () => _showDetails(context, task, techId),
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, Complaint c, String techId) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ComplaintDetails(complaint: c),
    );
  }

  Future<void> _resolveFlow(
    BuildContext context,
    Complaint c,
    String techId,
  ) async {
    final complaintProvider = context.read<ComplaintProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    final paths = picked.map((x) => x.path).toList();
    if (paths.isEmpty) {
      AppMessenger.showSnack("Add at least one after-fix photo to resolve.");
      return;
    }
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm resolve"),
          content: Text(
            "Resolve ticket ${c.id} with ${paths.length} fixed photo(s)?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    complaintProvider.resolveComplaint(
      complaintId: c.id,
      technicianId: techId,
      afterImagePaths: paths,
    );
    _notifyStudent(
      context,
      c.studentId,
      c.id,
      NotificationType.resolved,
      'Resolved',
      'Your complaint ${c.id} has been resolved. Please rate your experience.',
    );
    AppMessenger.showSnack("Resolved ${c.id} (fixed photos attached).");

    // Optional: immediately close after resolution (matches your UX request).
    if (!context.mounted) return;
    final closeConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Close ticket"),
          content: const Text(
            "Do you want to close this ticket now after confirming fixed photos?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Not now"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Close ticket"),
            ),
          ],
        );
      },
    );

    if (closeConfirmed != true) return;
    if (!context.mounted) return;
    complaintProvider.closeComplaint(complaintId: c.id);
    _notifyStudent(
      context,
      c.studentId,
      c.id,
      NotificationType.closed,
      'Closed',
      'Your complaint ${c.id} has been closed.',
    );
    AppMessenger.showSnack("Closed ${c.id}");
  }

  void _notifyStudent(
    BuildContext context,
    String studentId,
    String complaintId,
    NotificationType type,
    String title,
    String body,
  ) {
    context.read<NotificationProvider>().add(
      AppNotification(
        id: 'n-${DateTime.now().millisecondsSinceEpoch}',
        complaintId: complaintId,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        studentId: studentId,
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.queued});
  final List<Complaint> queued;

  @override
  Widget build(BuildContext context) {
    if (queued.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.warn.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  color: AppColors.warn,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Queue is empty",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "No complaints waiting for assignment",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: queued.length,
      itemBuilder: (context, index) {
        final c = queued[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ComplaintCard(
            complaint: c,
            trailing: SizedBox(
              width: 90, // 👈 IMPORTANT
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warn.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.warn,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "#${index + 1}",
                      style: const TextStyle(
                        color: AppColors.warn,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) =>
                  _ComplaintDetails(complaint: c, queuePosition: index + 1),
            ),
          ),
        );
      },
    );
  }
}

class _ResolvedList extends StatelessWidget {
  const _ResolvedList({required this.resolved});
  final List<Complaint> resolved;

  @override
  Widget build(BuildContext context) {
    if (resolved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "No resolved tasks",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Completed complaints will appear here",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: resolved.length,
      itemBuilder: (context, index) {
        final c = resolved[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ComplaintCard(
            complaint: c,
            trailing: SizedBox(
              width: 110, // IMPORTANT FIX
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonal(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) => _ComplaintDetails(complaint: c),
                    ),
                    child: const Text("View"),
                  ),
                  const SizedBox(height: 6),
                  IconButton(
                    tooltip: "Close ticket",
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    onPressed: () {
                      final complaintProvider = context
                          .read<ComplaintProvider>();
                      showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Close ticket"),
                            content: const Text(
                              "Are you sure issue is fully resolved?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Close"),
                              ),
                            ],
                          );
                        },
                      ).then((confirmed) {
                        if (confirmed == true) {
                          complaintProvider.closeComplaint(complaintId: c.id);
                          AppMessenger.showSnack("Closed ${c.id}");
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => _ComplaintDetails(complaint: c),
              );
            },
          ),
        );
      },
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({
    required this.complaint,
    required this.trailing,
    required this.onTap,
  });

  final Complaint complaint;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.surfaceContainerHighest, scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withAlpha(120)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withAlpha(60),
                        scheme.primary.withAlpha(20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      complaint.priority.name[0].toUpperCase(),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${complaint.categoryLabel} • ${complaint.block} ${complaint.room}",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        complaint.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // BUTTON (FIXED WIDTH ✅)
                SizedBox(width: 110, child: trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComplaintDetails extends StatefulWidget {
  const _ComplaintDetails({required this.complaint, this.queuePosition});
  final Complaint complaint;
  final int? queuePosition;

  @override
  State<_ComplaintDetails> createState() => _ComplaintDetailsState();
}

class _ComplaintDetailsState extends State<_ComplaintDetails> {
  bool _isResolving = false;

  Future<void> _startWork(Complaint c, String techId) async {
    if (!context.mounted) return;
    context.read<ComplaintProvider>().startWork(
      complaintId: c.id,
      technicianId: techId,
    );
    context.read<NotificationProvider>().add(
      AppNotification(
        id: 'n-${DateTime.now().millisecondsSinceEpoch}',
        complaintId: c.id,
        type: NotificationType.workStarted,
        title: 'Work started',
        body: '$techId has started working on your complaint ${c.id}.',
        createdAt: DateTime.now(),
        studentId: c.studentId,
      ),
    );
    AppMessenger.showSnack("Started work on ${c.id}");
    Navigator.pop(context);
  }

  Future<void> _resolveWithPhotos(Complaint c, String techId) async {
    setState(() => _isResolving = true);
    // Capture dependencies before awaiting (avoids using BuildContext after await).
    final complaintProvider = context.read<ComplaintProvider>();
    final navigator = Navigator.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    final paths = picked.map((x) => x.path).toList();
    if (paths.isEmpty) {
      if (!mounted) return;
      setState(() => _isResolving = false);
      AppMessenger.showSnack("Please attach at least one after-fix photo.");
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm resolve"),
          content: Text(
            "Resolve ticket ${c.id} with ${paths.length} fixed photo(s)?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isResolving = false);
      return;
    }

    complaintProvider.resolveComplaint(
      complaintId: c.id,
      technicianId: techId,
      afterImagePaths: paths,
    );
    context.read<NotificationProvider>().add(
      AppNotification(
        id: 'n-${DateTime.now().millisecondsSinceEpoch}',
        complaintId: c.id,
        type: NotificationType.resolved,
        title: 'Resolved',
        body:
            'Your complaint ${c.id} has been resolved. Please rate your experience.',
        createdAt: DateTime.now(),
        studentId: c.studentId,
      ),
    );
    setState(() => _isResolving = false);
    AppMessenger.showSnack("Resolved ${c.id} with fixed photos.");

    final closeConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Close ticket"),
          content: const Text(
            "Close ticket now after confirming fixed photos?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Not now"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (closeConfirmed == true) {
      complaintProvider.closeComplaint(complaintId: c.id);
      AppMessenger.showSnack("Closed ${c.id}");
    }

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final techId = context.watch<SessionProvider>().technicianId;
    final c = widget.complaint;

    final canStart =
        c.assignedTechnicianId == techId &&
        c.status == ComplaintStatus.assigned;
    final canResolve =
        c.assignedTechnicianId == techId &&
        (c.status == ComplaintStatus.assigned ||
            c.status == ComplaintStatus.inProgress);
    final canClose =
        c.assignedTechnicianId == techId &&
        c.status == ComplaintStatus.resolved;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ticket ${c.id}",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _pill(context, "Class", c.categoryLabel),
                  _pill(context, "Priority", c.priority.name),
                  _pill(context, "Status", c.status.name),
                  _pill(context, "Similar", "${c.similarCount} reports"),
                  if (widget.queuePosition != null)
                    _pill(context, "Queue", "#${widget.queuePosition}"),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                c.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                "Before photos",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              _imageStrip(context, c.beforeImagePaths),
              const SizedBox(height: AppSpacing.md),
              Text(
                "After photos",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              _imageStrip(context, c.afterImagePaths),
              const SizedBox(height: AppSpacing.md),
              Text(
                "AI notes",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                c.aiReasons.isEmpty
                    ? "No AI explanation available."
                    : c.aiReasons.join(" • "),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions
              if (c.status == ComplaintStatus.queued)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: scheme.surfaceContainerHighest,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    "In queue. You'll be able to start once promoted to Assigned.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    if (canStart)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          onPressed: () => _startWork(c, techId),
                          label: const Text("Start work"),
                        ),
                      ),
                    if (canResolve) ...[
                      if (canStart) const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: _isResolving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.build_rounded),
                          onPressed: _isResolving
                              ? null
                              : () => _resolveWithPhotos(c, techId),
                          label: const Text("Resolve (attach fixed photos)"),
                        ),
                      ),
                    ],
                    if (canClose) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Close ticket"),
                                  content: const Text(
                                    "Close after verifying fixed solution.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (!context.mounted) return;
                            if (confirmed == true) {
                              context.read<ComplaintProvider>().closeComplaint(
                                complaintId: c.id,
                              );
                              context.read<NotificationProvider>().add(
                                AppNotification(
                                  id: 'n-${DateTime.now().millisecondsSinceEpoch}',
                                  complaintId: c.id,
                                  type: NotificationType.closed,
                                  title: 'Closed',
                                  body:
                                      'Your complaint ${c.id} has been closed.',
                                  createdAt: DateTime.now(),
                                  studentId: c.studentId,
                                ),
                              );
                              AppMessenger.showSnack("Closed ${c.id}");
                              Navigator.pop(context);
                            }
                          },
                          label: const Text("Close ticket"),
                        ),
                      ),
                    ],
                    if (!canStart && !canResolve && !canClose)
                      const SizedBox(height: 0),
                  ],
                ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String k, String v) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "$k: $v",
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _imageStrip(BuildContext context, List<String> paths) {
    if (paths.isEmpty) {
      return Text(
        "None",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final p = paths[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(p),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TechNotificationButton extends StatelessWidget {
  const _TechNotificationButton({required this.techId});
  final String techId;

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationProvider>();
    final myNotifs = notif.forTechnician(techId);
    final unreadCount = myNotifs.where((n) => !n.read).length;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(context, myNotifs, notif),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 1.5),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(
    BuildContext context,
    List<AppNotification> notifications,
    NotificationProvider notif,
  ) {
    notif.markTechnicianRead(techId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: notifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final n = notifications[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.assignment,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
