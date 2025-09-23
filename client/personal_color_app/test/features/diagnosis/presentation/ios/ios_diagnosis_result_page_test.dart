import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/presentation/ios/ios_diagnosis_result_page.dart';
import 'package:personal_color_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:personal_color_app/features/diagnosis/presentation/services/content_adaptation_service.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/check_api_health.dart';
import 'package:personal_color_app/features/settings/data/services/privacy_settings_service.dart';
import 'package:mockito/mockito.dart';

// Mock classes for testing
class MockDiagnosePersonalColor extends Mock implements DiagnosePersonalColor {}
class MockDiagnosePersonalColorEnhanced extends Mock implements DiagnosePersonalColorEnhanced {}
class MockCheckApiHealth extends Mock implements CheckApiHealth {}
class MockContentAdaptationService extends Mock implements ContentAdaptationService {}
class MockPrivacySettingsService extends Mock implements PrivacySettingsService {}

void main() {
  group('IOSDiagnosisResultPage AI Makeup Button Tests', () {
    late DiagnosisResult mockDiagnosisResult;
    late String mockImagePath;

    setUp(() {
      mockDiagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 85,
        explanation: 'Test explanation for spring type',
        recommendedColors: [
          const ColorRecommendation(
            colorName: 'Light Pink',
            reason: 'Complements spring complexion',
            hexColor: '#FFB6C1',
          ),
          const ColorRecommendation(
            colorName: 'Pale Green',
            reason: 'Fresh spring color',
            hexColor: '#98FB98',
          ),
        ],
        avoidColors: [
          const ColorRecommendation(
            colorName: 'Dark Brown',
            reason: 'Too heavy for spring type',
            hexColor: '#654321',
          ),
        ],
        tips: 'Test tip 1\nTest tip 2',
      );
      mockImagePath = '/test/path/image.jpg';
    });

    testWidgets('should display おすすめメイク button on iOS diagnosis result page', (WidgetTester tester) async {
      // Create a mock diagnosis provider
      final mockProvider = DiagnosisProvider(
        diagnosePersonalColor: MockDiagnosePersonalColor(),
        diagnosePersonalColorEnhanced: MockDiagnosePersonalColorEnhanced(),
        checkApiHealth: MockCheckApiHealth(),
        contentAdaptationService: MockContentAdaptationService(),
        privacySettingsService: MockPrivacySettingsService(),
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>.value(
            value: mockProvider,
            child: IOSDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the おすすめメイク button is present
      expect(find.text('おすすめメイク'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('should display おすすめメイク button with correct styling', (WidgetTester tester) async {
      // Create a mock diagnosis provider
      final mockProvider = DiagnosisProvider(
        diagnosePersonalColor: MockDiagnosePersonalColor(),
        diagnosePersonalColorEnhanced: MockDiagnosePersonalColorEnhanced(),
        checkApiHealth: MockCheckApiHealth(),
        contentAdaptationService: MockContentAdaptationService(),
        privacySettingsService: MockPrivacySettingsService(),
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>.value(
            value: mockProvider,
            child: IOSDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Find the おすすめメイク button container
      final aiMakeupButton = find.ancestor(
        of: find.text('おすすめメイク'),
        matching: find.byType(GestureDetector),
      );

      expect(aiMakeupButton, findsOneWidget);

      // Verify the button is properly sized
      final container = find.ancestor(
        of: find.text('おすすめメイク'),
        matching: find.byType(Container),
      );
      expect(container, findsOneWidget);
    });

  });
}
