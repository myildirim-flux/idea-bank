import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_bank/features/notes/presentation/passphrase_setup_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PassphraseSetupPage Widget Tests', () {
    testWidgets('renders PassphraseSetupPage with key form elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PassphraseSetupPage(isChangePassphrase: false),
          ),
        ),
      );

      // Verify page title / headers render
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('displays error message when submitted with empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PassphraseSetupPage(isChangePassphrase: false),
          ),
        ),
      );

      // Find action button and tap
      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Expect validation error text to be visible
      expect(
        find.text('Password and confirmation cannot be empty.'),
        findsOneWidget,
      );
    });

    testWidgets('displays error message when passphrases do not match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PassphraseSetupPage(isChangePassphrase: false),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'secret123');
      await tester.enterText(textFields.at(1), 'mismatch321');

      final button = find.byType(ElevatedButton);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });
}
