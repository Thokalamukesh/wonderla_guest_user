// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
            'slug': 'bengaluru',
            'name': 'Wonderla Demo',
            'location': 'Demo City',
            'active': true,
            'events': [
              {'title': 'Demo Show', 'description': 'A park event'},
            ],
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
    expect(find.text('Explore Wonderla'), findsOneWidget);
    expect(find.text('Rides'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Rides & Events'), findsNothing);
    expect(find.text('Live Wait Times'), findsNothing);
    expect(find.text('Wave Pool & Rain Dance'), findsNothing);
    await tester.ensureVisible(find.text('Events'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO SHOW'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Park Map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Park Map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Demo Ride'), findsOneWidget);
    expect(find.text('Explore this park'), findsOneWidget);
    expect(find.text('1 place available'), findsOneWidget);
    expect(find.text('Wonderla Demo map'), findsNothing);
    expect(find.text('Map coordinates are needed'), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
