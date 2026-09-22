import 'package:flutter_test/flutter_test.dart';
import 'package:logria/app/logria_app.dart';

void main() {
  testWidgets('shows the Logria module shell', (tester) async {
    await tester.pumpWidget(const LogriaApp());

    expect(find.text('Logria'), findsOneWidget);
    expect(find.text('今日'), findsAtLeastNWidgets(1));
    expect(find.text('训练'), findsOneWidget);
    expect(find.text('饮食'), findsOneWidget);
    expect(find.text('身体'), findsOneWidget);
    expect(find.text('日历'), findsOneWidget);
  });
}
