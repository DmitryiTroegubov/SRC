// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/src/app.dart';

void main() {
  testWidgets('App shows Start Run button on startup', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RunnerApp()));
    await tester.pumpAndSettle();

    // The Run Tracker screen shows a FAB with label 'Start Run' when not tracking.
    expect(find.text('Start Run'), findsOneWidget);
    expect(find.text('Stop/Finish'), findsNothing);
  });
}
