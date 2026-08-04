// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_security_band_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This might fail because Firebase is not initialized in the test environment,
    // but we fix the syntax error regardless.
    await tester.pumpWidget(const SmartSecurityApp());
  });
}
