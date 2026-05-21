import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myakuari_ai/presentation/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('恋愛波形解析エンジン'), findsOneWidget);
  });
}


