import 'package:flutter_test/flutter_test.dart';

import 'package:somaiya_guessr/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SomaiyaGuessrApp());

    expect(find.text('SOMAIYA GUESSR'), findsOneWidget);
  });
}
