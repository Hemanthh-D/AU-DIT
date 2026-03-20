// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_ai_complaint_app/main.dart';
import 'package:campus_ai_complaint_app/core/session/session_provider.dart';
import 'package:campus_ai_complaint_app/providers/complaint_provider.dart';

void main() {
  testWidgets('App boots to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SessionProvider()),
          ChangeNotifierProvider(create: (_) => ComplaintProvider()),
        ],
        child: const AUDITApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
