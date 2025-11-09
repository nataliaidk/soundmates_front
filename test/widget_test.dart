// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:zpi_test/widgets/city_map_preview.dart';

void main() {
  testWidgets('CityMapPreview shows placeholder when no center', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CityMapPreview(center: null, cityName: 'Testville'))));
    expect(find.textContaining('Testville'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });

  testWidgets('CityMapPreview renders city name with coordinates', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CityMapPreview(center: LatLng(52.2297, 21.0122), cityName: 'Warsaw'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Warsaw'), findsOneWidget);
  });
}
