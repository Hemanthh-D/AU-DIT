import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key, required this.child});

  final Widget child;

  static const tabs = <_TabSpec>[
    _TabSpec(label: 'Home', icon: Icons.home_outlined, location: '/student/home'),
    _TabSpec(
      label: 'Submit',
      icon: Icons.add_circle_outline,
      location: '/student/submit',
    ),
    _TabSpec(
      label: 'Status',
      icon: Icons.track_changes_outlined,
      location: '/student/status',
    ),
    _TabSpec(
      label: 'Profile',
      icon: Icons.person_outline,
      location: '/student/profile',
    ),
  ];

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> with TickerProviderStateMixin {
  int _indexForLocation(String location) {
    for (var i = 0; i < StudentShell.tabs.length; i++) {
      if (location.startsWith(StudentShell.tabs[i].location)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.99, end: 1).animate(fade),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (idx) {
            final target = StudentShell.tabs[idx].location;
            if (target == location) return;
            context.go(target);
          },
          elevation: 0,
          height: 70,
          destinations: [
            for (final t in StudentShell.tabs)
              NavigationDestination(
                icon: Icon(t.icon),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.label, required this.icon, required this.location});
  final String label;
  final IconData icon;
  final String location;
}

