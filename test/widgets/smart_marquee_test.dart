import 'package:ezze_music/ui/widgets/shared/smart_marquee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartMarquee Widget Tests', () {
    testWidgets('Renders static Text when text fits within bounds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: SmartMarquee(
                text: 'Short',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Short'), findsOneWidget);
    });
  });
}
