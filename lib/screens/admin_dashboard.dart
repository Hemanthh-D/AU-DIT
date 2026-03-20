import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../models/app_notification.dart';
import '../models/complaint.dart';
import '../providers/complaint_provider.dart';
import '../providers/notification_provider.dart';
import '../core/session/session_provider.dart';
import '../core/ui/app_spacing.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<String> _technicians = ['Unassigned', 'Tech 1', 'Tech 2', 'Counselor'];
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all'; // all, open, active, resolved, closed
  String _categoryFilter = 'all';

  VoidCallback? _searchListener;

  @override
  void initState() {
    super.initState();
    _searchListener = () => setState(() {});
    _searchController.addListener(_searchListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComplaintProvider>().checkEscalations();
    });
  }

  @override
  void dispose() {
    if (_searchListener != null) {
      _searchController.removeListener(_searchListener!);
    }
    _searchController.dispose();
    super.dispose();
  }

  List<Complaint> _filteredComplaints(List<Complaint> complaints) {
    var list = complaints;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        return c.description.toLowerCase().contains(query) ||
            c.id.toLowerCase().contains(query) ||
            c.categoryLabel.toLowerCase().contains(query) ||
            c.block.toLowerCase().contains(query) ||
            c.room.toLowerCase().contains(query);
      }).toList();
    }
    if (_statusFilter != 'all') {
      list = list.where((c) {
        return switch (_statusFilter) {
          'open' => c.status == ComplaintStatus.submitted || c.status == ComplaintStatus.queued,
          'active' => c.status == ComplaintStatus.assigned || c.status == ComplaintStatus.inProgress,
          'resolved' => c.status == ComplaintStatus.resolved,
          'closed' => c.status == ComplaintStatus.closed,
          _ => true,
        };
      }).toList();
    }
    if (_categoryFilter != 'all') {
      list = list.where((c) => c.categoryLabel == _categoryFilter).toList();
    }
    list = List.from(list)..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final complaints = context.watch<ComplaintProvider>().complaints;
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final openCount = complaints.where((c) =>
        c.status == ComplaintStatus.submitted || c.status == ComplaintStatus.queued).length;
    final activeCount = complaints.where((c) =>
        c.status == ComplaintStatus.assigned || c.status == ComplaintStatus.inProgress).length;
    final resolvedCount = complaints.where((c) => c.status == ComplaintStatus.resolved).length;
    final closedCount = complaints.where((c) => c.status == ComplaintStatus.closed).length;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.admin_panel_settings_rounded, color: scheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin Portal', style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text('AU-DIT Campus Management',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => _showProfileSheet(context),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<SessionProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TasksTab(
            complaints: _filteredComplaints(complaints),
            allComplaints: complaints,
            technicians: _technicians,
            searchController: _searchController,
            statusFilter: _statusFilter,
            categoryFilter: _categoryFilter,
            onStatusFilterChanged: (v) => setState(() => _statusFilter = v),
            onCategoryFilterChanged: (v) => setState(() => _categoryFilter = v),
            openCount: openCount,
            activeCount: activeCount,
            resolvedCount: resolvedCount,
            closedCount: closedCount,
          ),
          _AnalyticsTab(complaints: complaints, isDark: isDark),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    final session = context.read<SessionProvider>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(session.email ?? 'Admin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('Administrator',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              value: session.darkMode,
              onChanged: session.setDarkMode,
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Log out'),
              onTap: () {
                session.logout();
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TASKS TAB ─────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  const _TasksTab({
    required this.complaints,
    required this.allComplaints,
    required this.technicians,
    required this.searchController,
    required this.statusFilter,
    required this.categoryFilter,
    required this.onStatusFilterChanged,
    required this.onCategoryFilterChanged,
    required this.openCount,
    required this.activeCount,
    required this.resolvedCount,
    required this.closedCount,
  });

  final List<Complaint> complaints;
  final List<Complaint> allComplaints;
  final List<String> technicians;
  final TextEditingController searchController;
  final String statusFilter;
  final String categoryFilter;
  final void Function(String) onStatusFilterChanged;
  final void Function(String) onCategoryFilterChanged;
  final int openCount;
  final int activeCount;
  final int resolvedCount;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = allComplaints.map((c) => c.categoryLabel).toSet().toList()..sort();

    return RefreshIndicator(
      onRefresh: () async => context.read<ComplaintProvider>().refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(
                    open: openCount,
                    active: activeCount,
                    resolved: resolvedCount,
                    closed: closedCount,
                    scheme: scheme,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Complaints', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by ID, description, block, room…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: statusFilter == 'all',
                          onTap: () => onStatusFilterChanged('all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Open',
                          selected: statusFilter == 'open',
                          onTap: () => onStatusFilterChanged('open'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Active',
                          selected: statusFilter == 'active',
                          onTap: () => onStatusFilterChanged('active'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Resolved',
                          selected: statusFilter == 'resolved',
                          onTap: () => onStatusFilterChanged('resolved'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Closed',
                          selected: statusFilter == 'closed',
                          onTap: () => onStatusFilterChanged('closed'),
                        ),
                      ],
                    ),
                  ),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All categories',
                            selected: categoryFilter == 'all',
                            onTap: () => onCategoryFilterChanged('all'),
                          ),
                          ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label: cat,
                              selected: categoryFilter == cat,
                              onTap: () => onCategoryFilterChanged(cat),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (complaints.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No complaints match your filters.',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final c = complaints[index];
                    return _ComplaintCard(
                      complaint: c,
                      technicians: technicians,
                      onAssign: (tech) {
                        context.read<ComplaintProvider>().assignTechnician(
                              complaintId: c.id,
                              technician: tech,
                            );
                        if (tech != 'Unassigned') {
                          context.read<NotificationProvider>().add(AppNotification(
                                id: 'n-${DateTime.now().millisecondsSinceEpoch}',
                                complaintId: c.id,
                                type: NotificationType.technicianAssigned,
                                title: 'Technician assigned',
                                body: '$tech has been assigned to your complaint ${c.id}.',
                                createdAt: DateTime.now(),
                                studentId: c.studentId,
                              ));
                          context.read<NotificationProvider>().add(AppNotification(
                                id: 'n-t-${DateTime.now().millisecondsSinceEpoch}',
                                complaintId: c.id,
                                type: NotificationType.technicianAssigned,
                                title: 'New complaint assigned',
                                body: '${c.categoryLabel} • ${c.block} ${c.room} — admin assigned to you.',
                                createdAt: DateTime.now(),
                                technicianId: tech,
                              ));
                        }
                      },
                    );
                  },
                  childCount: complaints.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.open,
    required this.active,
    required this.resolved,
    required this.closed,
    required this.scheme,
  });

  final int open;
  final int active;
  final int resolved;
  final int closed;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile('Open', open, scheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile('Active', active, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile('Resolved', resolved, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _StatTile('Closed', closed, Colors.grey)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({
    required this.complaint,
    required this.technicians,
    required this.onAssign,
  });

  final Complaint complaint;
  final List<String> technicians;
  final void Function(String) onAssign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = complaint;
    final value = technicians.contains(c.assignedTechnicianId)
        ? c.assignedTechnicianId
        : 'Unassigned';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(c.categoryLabel, scheme.primaryContainer, scheme.onPrimaryContainer),
                if (c.isEscalated) ...[
                  const SizedBox(width: 8),
                  _Badge('ESCALATED', Colors.orange.shade100, Colors.orange.shade900),
                ],
                const SizedBox(width: 8),
                _Badge(c.priority.name.toUpperCase(), _priorityColor(c.priority).withAlpha(40), _priorityColor(c.priority)),
                const Spacer(),
                _Badge(c.status.name, scheme.surfaceContainerHighest, scheme.onSurface),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(c.description,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${c.block} • ${c.room} • ${c.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.engineering_outlined, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('Assign:', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      items: technicians.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))).toList(),
                      onChanged: (v) {
                        if (v != null) onAssign(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(ComplaintPriority p) {
    return switch (p) {
      ComplaintPriority.urgent => Colors.red,
      ComplaintPriority.high => Colors.orange,
      ComplaintPriority.medium => Colors.amber,
      ComplaintPriority.low => Colors.green,
    };
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.bg, this.fg);

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3)),
    );
  }
}

// ─── ANALYTICS TAB ─────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.complaints, required this.isDark});

  final List<Complaint> complaints;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final byCategory = <String, int>{};
    for (final c in complaints) {
      byCategory[c.categoryLabel] = (byCategory[c.categoryLabel] ?? 0) + 1;
    }
    final byPriority = <String, int>{};
    for (final c in complaints) {
      byPriority[c.priority.name] = (byPriority[c.priority.name] ?? 0) + 1;
    }
    final byStatus = <String, int>{};
    for (final c in complaints) {
      byStatus[c.status.name] = (byStatus[c.status.name] ?? 0) + 1;
    }
    final byTechnician = <String, int>{};
    for (final c in complaints) {
      final t = c.assignedTechnicianId;
      byTechnician[t] = (byTechnician[t] ?? 0) + 1;
    }
    final bySatisfaction = <int, int>{};
    for (final c in complaints) {
      final r = c.satisfactionRating;
      if (r != null) bySatisfaction[r] = (bySatisfaction[r] ?? 0) + 1;
    }

    final maxCat = byCategory.values.isEmpty ? 1 : byCategory.values.reduce((a, b) => a > b ? a : b);
    final maxTech = byTechnician.values.isEmpty ? 1 : byTechnician.values.reduce((a, b) => a > b ? a : b);

    final barColors = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('System Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Analytics based on ${complaints.length} total complaints',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xl),

        _ChartCard(
          title: 'By Category',
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 8),
            child: byCategory.isEmpty
              ? const _EmptyChart()
              : SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxCat * 1.2).clamp(1, double.infinity),
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            final entries = byCategory.entries.toList();
                            if (i < 0 || i >= entries.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                entries[i].key.length > 10
                                    ? '${entries[i].key.substring(0, 10)}…'
                                    : entries[i].key,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700),
                              ),
                            );
                          },
                          reservedSize: 36,
                        )),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (v) => FlLine(
                            color: scheme.outlineVariant.withAlpha(80),
                            strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: byCategory.entries.toList().asMap().entries.map((e) {
                        final i = e.key;
                        final entry = e.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: barColors[i % barColors.length],
                              width: 28,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                          showingTooltipIndicators: [0],
                        );
                      }).toList(),
                    ),
                  ),
                ),
          ),
        ),

        _ChartCard(
          title: 'By Priority',
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: byPriority.isEmpty
              ? const _EmptyChart()
              : SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 36,
                            sections: byPriority.entries.toList().asMap().entries.map((e) {
                              final entry = e.value;
                              final pct = complaints.isEmpty ? 0.0 : entry.value / complaints.length;
                              return PieChartSectionData(
                                value: entry.value.toDouble(),
                                title: '${(pct * 100).round()}%',
                                color: _priorityChartColor(entry.key),
                                radius: 32,
                                titleStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: _priorityChartColor(entry.key).computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: byPriority.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _priorityChartColor(e.key),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text('${e.key}: ${e.value}',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),

        _ChartCard(
          title: 'By Technician Workload',
          child: byTechnician.isEmpty
              ? const _EmptyChart()
              : Column(
                  children: byTechnician.entries.map((e) {
                    final pct = maxTech <= 0 ? 0.0 : e.value / maxTech;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800)),
                              Text('${e.value}', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: scheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                  barColors[byTechnician.keys.toList().indexOf(e.key) % barColors.length]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: AppSpacing.lg),

        if (bySatisfaction.isNotEmpty) ...[
          _ChartCard(
            title: 'Satisfaction (1–5 stars)',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 4, 5].map((star) {
                  final count = bySatisfaction[star] ?? 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$count', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900, color: scheme.primary)),
                      const SizedBox(height: 4),
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      Text('$star', style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],

        _ChartCard(
          title: 'By Status',
          child: byStatus.isEmpty
              ? const _EmptyChart()
              : Column(
                  children: byStatus.entries.map((e) {
                    final color = _statusColor(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(e.key,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ),
                          Text('${e.value}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900, color: color)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Color _priorityChartColor(String p) {
    return switch (p.toLowerCase()) {
      'urgent' => Colors.red,
      'high' => Colors.orange,
      'medium' => Colors.amber,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }

  Color _statusColor(String s) {
    return switch (s.toLowerCase()) {
      'submitted' || 'queued' => Colors.blue,
      'assigned' || 'inprogress' => Colors.orange,
      'resolved' => Colors.green,
      'closed' => Colors.grey,
      _ => Colors.teal,
    };
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150)),
            const SizedBox(height: 8),
            Text('No data yet', style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
