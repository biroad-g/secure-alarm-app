import 'package:flutter_test/flutter_test.dart';
import 'package:secure_alarm/main.dart';

void main() {
  testWidgets('SecureAlarm smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureAlarmApp());
    expect(find.text('Secure Alarm'), findsOneWidget);
  });
}
