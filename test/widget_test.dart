import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Edmaster/main.dart';
import 'package:Edmaster/login.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(initialPage: MyHomePage(), isLoggedIn: false),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
