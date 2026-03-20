import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/session_provider.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/app_spacing.dart';
import '../providers/notification_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Icon(Icons.person_rounded, color: AppColors.teal, size: 24),
            const SizedBox(width: 12),
            const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Icon(Icons.person, color: scheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.email ?? 'Student',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Student ID: ${session.studentId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: session.darkMode,
                  onChanged: session.setDarkMode,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: context.watch<NotificationProvider>().enabled,
                  onChanged: (v) => context.read<NotificationProvider>().setEnabled(v),
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('In-app notifications'),
                  subtitle: const Text('Status updates for your complaints'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('AU-DIT • Campus complaint system'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AU-DIT',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'Demo build',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Log out'),
              onTap: () {
                context.read<SessionProvider>().logout();
                context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

