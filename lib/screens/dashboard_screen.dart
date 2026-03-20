import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/session_provider.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_spacing.dart';
import '../models/app_notification.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';
import '../providers/notification_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showGuidelines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            ListTile(
              leading: Icon(Icons.rule_folder_outlined),
              title: Text("How complaints work"),
              subtitle: Text("Submit → Admin assigns → Technician updates status."),
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text("Privacy"),
              subtitle: Text("Avoid sharing sensitive personal information."),
            ),
            ListTile(
              leading: Icon(Icons.warning_amber_outlined),
              title: Text("Urgent issues"),
              subtitle: Text("Use clear keywords; urgent items get higher priority."),
            ),
          ],
        );
      },
    );
  }

  void _showSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text("Email helpdesk"),
              subtitle: Text("support@campus.edu"),
            ),
            ListTile(
              leading: Icon(Icons.call_outlined),
              title: Text("Call"),
              subtitle: Text("+91-90000-00000"),
            ),
            ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text("Hours"),
              subtitle: Text("Mon–Sat • 9:00 AM – 6:00 PM"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<SessionProvider>();
    final complaints = context.watch<ComplaintProvider>().complaints
        .where((c) => c.studentId == session.studentId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    final openCount =
        complaints.where((c) => c.status != ComplaintStatus.resolved).length;
    final resolvedCount =
        complaints.where((c) => c.status == ComplaintStatus.resolved).length;

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
                color: AppColors.teal.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Student Portal", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          ],
        ),
        actions: [
          _NotificationButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, ${session.email ?? 'Student'}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Submit a complaint and track updates in real time.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: "Open",
                    value: openCount.toString(),
                    icon: Icons.pending_actions_outlined,
                    tint: AppColors.indigoTint,
                    accent: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    label: "Resolved",
                    value: resolvedCount.toString(),
                    icon: Icons.verified_outlined,
                    tint: AppColors.greenTint,
                    accent: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            Text(
              "Quick actions",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.15,
              children: [
                _ActionTile(
                  title: "New report",
                  subtitle: "Submit a complaint",
                  icon: Icons.add_chart_outlined,
                  tint: AppColors.pinkTint,
                  accent: AppColors.danger,
                  onTap: () => context.go('/student/submit'),
                ),
                _ActionTile(
                  title: "Track status",
                  subtitle: "See latest updates",
                  icon: Icons.track_changes_outlined,
                  tint: AppColors.indigoTint,
                  accent: AppColors.info,
                  onTap: () => context.go('/student/status'),
                ),
                _ActionTile(
                  title: "Guidelines",
                  subtitle: "Rules & FAQs",
                  icon: Icons.menu_book_outlined,
                  tint: AppColors.greenTint,
                  accent: AppColors.success,
                  onTap: () => _showGuidelines(context),
                ),
                _ActionTile(
                  title: "Support",
                  subtitle: "Contact helpdesk",
                  icon: Icons.support_agent_outlined,
                  tint: scheme.surfaceContainerHighest,
                  accent: scheme.onSurface,
                  onTap: () => _showSupport(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/student/status'),
                  child: const Text("View all"),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (complaints.isEmpty)
              const _EmptyRecent()
            else
              ...complaints.take(3).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RecentComplaintCard(
                        id: c.id,
                        title: c.categoryLabel,
                        description: c.description,
                        status: c.status.name,
                        priority: c.priority.name,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onTapDown: (_) => HapticFeedback.selectionClick(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentComplaintCard extends StatelessWidget {
  const _RecentComplaintCard({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;

  Color _priorityColor() {
    return switch (priority.toLowerCase()) {
      'urgent' => AppColors.danger,
      'high' => AppColors.danger,
      'medium' => AppColors.warn,
      _ => AppColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priColor = _priorityColor();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Chip(text: priority.toUpperCase(), color: priColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  id,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                _Chip(
                  text: status,
                  color: scheme.onSurface,
                  background: scheme.surfaceContainerHighest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.color,
    this.background,
  });

  final String text;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.indigoTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.inbox_outlined, color: AppColors.info),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                "No complaints yet. Create your first report to start tracking updates.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final notif = context.watch<NotificationProvider>();
    final myNotifs = notif.forStudent(session.studentId);
    final unreadCount = myNotifs.where((n) => !n.read).length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
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
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
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
    notif.markAllRead();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        notif.clear();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Clear all'),
                    ),
                ],
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
                            Icon(Icons.notifications_none, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final n = notifications[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(_iconFor(n.type), color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
                          ),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType t) {
    return switch (t) {
      NotificationType.technicianAssigned => Icons.engineering,
      NotificationType.workStarted => Icons.play_arrow,
      NotificationType.resolved => Icons.check_circle,
      NotificationType.closed => Icons.done_all,
      NotificationType.escalated => Icons.priority_high,
    };
  }
}
