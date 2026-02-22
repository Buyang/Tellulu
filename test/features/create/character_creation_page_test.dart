import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:tellulu/features/create/character_creation_page.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

import 'character_creation_page_test.mocks.dart';

@GenerateMocks([GeminiService, StabilityService])
void main() {
  late MockGeminiService mockGeminiService;
  late MockStabilityService mockStabilityService;

  setUp(() {
    mockGeminiService = MockGeminiService();
    mockStabilityService = MockStabilityService();
  });

  testWidgets('CharacterCreationPage renders correctly', (WidgetTester tester) async {
    // Build the widget in a ProviderScope (required for Riverpod)
    // We inject mocks into the widget to avoid real API calls
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CharacterCreationPage(
            geminiService: mockGeminiService,
            stabilityService: mockStabilityService,
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Who is the hero today?'), findsOneWidget);
    expect(find.text('Bring a new friend...'), findsOneWidget);

    // Verify Buttons
    expect(find.text('3. Dream Up More'), findsOneWidget);
    expect(find.text('1. Pick Actor'), findsOneWidget); // Also updating this for consistency
    expect(find.text('Draw it!'), findsOneWidget);

    // Verify Style Chips (at least one)
    expect(find.text('Digital Art'), findsOneWidget);
    expect(find.text('Anime'), findsOneWidget);

    // Verify Input Field
    expect(find.byType(TextField), findsAtLeastNWidgets(1));
    expect(find.text('Describe your hero...'), findsOneWidget);

    // Verify Cast Section
    expect(find.text('Your Cast'), findsOneWidget);
  });
}
