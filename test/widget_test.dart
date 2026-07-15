import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nike_rerun/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const NikeReRunApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
