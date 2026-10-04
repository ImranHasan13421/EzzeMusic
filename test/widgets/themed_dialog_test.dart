import 'package:ezze_music/ui/widgets/shared/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemedInputDialog Widget Tests', () {
    testWidgets('Renders title, text field, cancel and confirm buttons', (tester) async {
      final controller = TextEditingController(text: 'My Playlist');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemedInputDialog(
              title: 'Create Playlist',
              hint: 'Enter playlist name',
              confirmLabel: 'Save',
              controller: controller,
              accentColor: const Color(0xFF6366F1),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Playlist'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('My Playlist'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Late Night Jazz');
      expect(controller.text, equals('Late Night Jazz'));
    });
  });
}
