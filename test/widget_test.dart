import 'package:flutter_test/flutter_test.dart';

import 'package:smartbank_ai/main.dart';

void main() {
  testWidgets('Counter test',
      (WidgetTester tester) async {

    await tester.pumpWidget(
      const SmartBankAI(),
    );

    expect(find.text('0'),
        findsOneWidget);
  });
}