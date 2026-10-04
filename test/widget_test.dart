import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:logria/app/logria_app.dart';
import 'package:logria/core/database/app_database.dart';

void main() {
  testWidgets('shows the Logria module shell', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(LogriaApp(database: database));

    expect(find.text('Logria'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.pumpWidget(const SizedBox());
  });
}
