import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/session/session_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_messenger.dart';
import 'providers/complaint_provider.dart';
import 'providers/notification_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const AUDITApp(),
    ),
  );
}

class AUDITApp extends StatelessWidget {
  const AUDITApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final router = AppRouter.create(session);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AU-DIT',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: session.darkMode ? ThemeMode.dark : ThemeMode.light,
      scaffoldMessengerKey: AppMessenger.key,
      routerConfig: router,
    );
  }
}
