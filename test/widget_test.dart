// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maps_wonderla_flutter/features/home/visitor_home.dart';

void main() {
  testWidgets('park visitor home opens its configured park map', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VisitorHome(
          initialPark: {
            'slug': 'demo',
            'name': 'Wonderla Demo',
            'location': 'Demo City',
            'active': true,
            'parkMap': {
              'img': '',
              'description': '',
              'zones': <dynamic>[],
              'places': [
                {'name': 'Demo Ride', 'category': 'Ride', 'x': 50, 'y': 50},
              ],
            },
          },
        ),
      ),
    );
    expect(find.text('EXPLORE THE PARK'), findsOneWidget);
    await tester.tap(find.text('PARK MAP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Demo Ride'), findsOneWidget);
    expect(find.text('Explore this park'), findsOneWidget);
    expect(find.text('1 place available'), findsOneWidget);
    expect(find.text('Wonderla Demo map'), findsNothing);
  });
}
