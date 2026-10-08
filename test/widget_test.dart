import 'package:flutter_test/flutter_test.dart';
import 'package:jobsense/app/app.dart';

void main() {
  testWidgets('JobSenseApp splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JobSenseApp());

    // Verify that JobSense title is displayed on splash
    expect(find.text('JobSense'), findsOneWidget);
    expect(find.text('Personalized Government Job Alerts'), findsOneWidget);

    // Fast-forward past splash timer to LoginScreen
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify that LoginScreen is rendered
    expect(find.text('Welcome to JobSense'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
