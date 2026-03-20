import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

import '../session/session_provider.dart';
import '../../screens/admin_dashboard.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/student_shell.dart';
import '../../screens/submit_complaint.dart';
import '../../screens/complaint_status.dart';
import '../../screens/technician_panel.dart';

class AppRouter {
  static GoRouter create(SessionProvider session) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: session,
      redirect: (context, state) {
        final loggedIn = session.isLoggedIn;
        final isLogin = state.matchedLocation == '/login';

        if (!loggedIn) {
          return isLogin ? null : '/login';
        }

        if (isLogin) {
          return switch (session.role) {
            UserRole.admin => '/admin',
            UserRole.technician => '/tech',
            UserRole.student => '/student/home',
            _ => '/login',
          };
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => StudentShell(child: child),
          routes: [
            GoRoute(
              path: '/student/home',
              pageBuilder: (context, state) => _fade(state, const DashboardScreen()),
            ),
            GoRoute(
              path: '/student/submit',
              pageBuilder: (context, state) => _fade(state, const SubmitComplaintScreen()),
            ),
            GoRoute(
              path: '/student/status',
              pageBuilder: (context, state) => _fade(state, const ComplaintStatusScreen()),
            ),
            GoRoute(
              path: '/student/profile',
              pageBuilder: (context, state) => _fade(state, const ProfileScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/tech',
          builder: (context, state) => const TechnicianPanel(),
        ),
      ],
    );
  }
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

