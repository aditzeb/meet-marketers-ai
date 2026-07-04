import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_marketers_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MeetMarketersApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
