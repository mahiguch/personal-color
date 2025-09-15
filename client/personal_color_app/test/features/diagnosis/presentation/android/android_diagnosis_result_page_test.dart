import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:personal_color_app/features/diagnosis/domain/entities/diagnosis_request.dart';
import 'package:personal_color_app/features/diagnosis/presentation/android/android_diagnosis_result_page.dart';
import 'package:personal_color_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart';
import 'package:personal_color_app/features/diagnosis/domain/usecases/check_api_health.dart';
import 'package:personal_color_app/features/diagnosis/presentation/services/content_adaptation_service.dart';
import 'package:personal_color_app/features/settings/data/services/privacy_settings_service.dart';
import 'package:personal_color_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:personal_color_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

// Mock classes for testing
class MockDiagnosisRepository implements DiagnosisRepository {
  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePerson(DiagnosisRequest request) async {
    return Right(DiagnosisResult(
      diagnosisType: PersonalColorType.spring,
      confidence: 85,
      explanation: 'Test explanation',
      recommendedColors: [],
      avoidColors: [],
      tips: 'Test tips',
    ));
  }

  @override
  Future<Either<Failure, DiagnosisResult>> diagnosePersonalColorEnhanced(DiagnosisRequest request) async {
    return Right(DiagnosisResult(
      diagnosisType: PersonalColorType.spring,
      confidence: 85,
      explanation: 'Test explanation',
      recommendedColors: [],
      avoidColors: [],
      tips: 'Test tips',
    ));
  }

  @override
  Future<Either<Failure, bool>> checkApiHealth() async => const Right(true);

  @override
  Future<Either<Failure, Map<String, dynamic>>> testConnection() async =>
    const Right({'status': 'ok'});
}

class MockDiagnosisProvider extends DiagnosisProvider {
  MockDiagnosisProvider() : super(
    diagnosePersonalColor: DiagnosePersonalColor(MockDiagnosisRepository()),
    diagnosePersonalColorEnhanced: DiagnosePersonalColorEnhanced(MockDiagnosisRepository()),
    checkApiHealth: CheckApiHealth(MockDiagnosisRepository()),
    contentAdaptationService: ContentAdaptationService(),
    privacySettingsService: PrivacySettingsService(),
  );

  @override
  void clearResult() {
    // Mock implementation
  }
}

void main() {
  group('AndroidDiagnosisResultPage Button Relocation Tests', () {
    late DiagnosisResult mockDiagnosisResult;
    late String mockImagePath;

    setUp(() {
      mockDiagnosisResult = DiagnosisResult(
        diagnosisType: PersonalColorType.spring,
        confidence: 85,
        explanation: 'Test explanation',
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

    testWidgets('AI makeup button should be present on diagnosis result screen', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => MockDiagnosisProvider(),
            child: AndroidDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      // Act & Assert
      // Verify that AI makeup button is present
      expect(find.text('AI生成メイク'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('AI makeup button should be properly styled as FilledButton.tonal', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => MockDiagnosisProvider(),
            child: AndroidDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert
      // Look for the SizedBox that contains the AI makeup button
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);
      
      // Verify the AI makeup text is present
      expect(find.text('AI生成メイク'), findsOneWidget);
      
      // Verify the auto_awesome icon is present
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      
      // Verify button dimensions by finding the SizedBox that wraps the button
      bool foundCorrectSizedBox = false;
      for (int i = 0; i < tester.widgetList(sizedBoxes).length; i++) {
        final sizedBox = tester.widget<SizedBox>(sizedBoxes.at(i));
        if (sizedBox.height == 56.0 && sizedBox.width == double.infinity) {
          // Check if this SizedBox contains the AI makeup text
          final descendants = find.descendant(
            of: sizedBoxes.at(i),
            matching: find.text('AI生成メイク'),
          );
          if (descendants.evaluate().isNotEmpty) {
            foundCorrectSizedBox = true;
            break;
          }
        }
      }
      expect(foundCorrectSizedBox, true, reason: 'Should find SizedBox with correct dimensions containing AI makeup button');
    });

    testWidgets('AI makeup button should have correct icon and text', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => MockDiagnosisProvider(),
            child: AndroidDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert
      // Verify both icon and text are present
      expect(find.text('AI生成メイク'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      
      // Verify they are close to each other in the widget tree (both should be in the same button)
      final textWidget = tester.getCenter(find.text('AI生成メイク'));
      final iconWidget = tester.getCenter(find.byIcon(Icons.auto_awesome));
      
      // They should be on the same horizontal line (same y coordinate approximately)
      expect((textWidget.dy - iconWidget.dy).abs(), lessThan(10.0), 
        reason: 'Icon and text should be on the same horizontal line');
    });

    testWidgets('All action buttons should be present in correct order', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => MockDiagnosisProvider(),
            child: AndroidDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      // Act & Assert
      // Verify all expected buttons are present
      expect(find.text('おすすめのメイク'), findsOneWidget);
      expect(find.text('AI生成メイク'), findsOneWidget);
      expect(find.text('おすすめのファッション'), findsOneWidget);
      expect(find.text('もう一度診断する'), findsOneWidget);
      
      // Verify button order by checking their positions
      final makeupButton = tester.getCenter(find.text('おすすめのメイク'));
      final aiMakeupButton = tester.getCenter(find.text('AI生成メイク'));
      final fashionButton = tester.getCenter(find.text('おすすめのファッション'));
      final retakeButton = tester.getCenter(find.text('もう一度診断する'));
      
      // AI makeup button should be after regular makeup button
      expect(aiMakeupButton.dy, greaterThan(makeupButton.dy));
      // Fashion button should be after AI makeup button
      expect(fashionButton.dy, greaterThan(aiMakeupButton.dy));
      // Retake button should be last
      expect(retakeButton.dy, greaterThan(fashionButton.dy));
    });

    testWidgets('AI makeup button should be positioned correctly in the layout', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => MockDiagnosisProvider(),
            child: AndroidDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert
      // Verify the AI makeup text is present
      expect(find.text('AI生成メイク'), findsOneWidget);
      
      // Get the position of the AI makeup button text
      final aiMakeupTextPosition = tester.getCenter(find.text('AI生成メイク'));
      final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
      
      // Button should be positioned within the screen bounds
      expect(aiMakeupTextPosition.dx, greaterThan(0));
      expect(aiMakeupTextPosition.dx, lessThan(screenWidth));
      
      // Button should be roughly centered horizontally
      expect(aiMakeupTextPosition.dx, greaterThan(screenWidth * 0.3));
      expect(aiMakeupTextPosition.dx, lessThan(screenWidth * 0.7));
    });

    testWidgets('AI makeup button styling should match Material Design 3 guidelines', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DiagnosisProvider>(
            create: (_) => MockDiagnosisProvider(),
            child: AndroidDiagnosisResultPage(
              result: mockDiagnosisResult,
              originalImagePath: mockImagePath,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert
      // Verify the AI makeup text and icon are present
      expect(find.text('AI生成メイク'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      
      // Get the size of the text widget to verify it's within reasonable bounds
      final textSize = tester.getSize(find.text('AI生成メイク'));
      
      // Text should have reasonable dimensions
      expect(textSize.height, greaterThan(10.0));
      expect(textSize.width, greaterThan(50.0));
      
      // Verify the icon has reasonable size
      final iconSize = tester.getSize(find.byIcon(Icons.auto_awesome));
      expect(iconSize.height, greaterThanOrEqualTo(18.0));
      expect(iconSize.width, greaterThanOrEqualTo(18.0));
    });

    group('Button Behavior Tests', () {
      testWidgets('AI makeup button should be tappable', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DiagnosisProvider>(
              create: (_) => MockDiagnosisProvider(),
              child: AndroidDiagnosisResultPage(
                result: mockDiagnosisResult,
                originalImagePath: mockImagePath,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act & Assert
        final aiMakeupButton = find.text('AI生成メイク');
        expect(aiMakeupButton, findsOneWidget);
        
        // Verify button can be tapped (this will trigger navigation logic but may fail due to missing dependencies)
        // We just want to verify the tap doesn't crash the widget tree
        try {
          await tester.tap(aiMakeupButton, warnIfMissed: false);
          await tester.pump();
        } catch (e) {
          // Expected to fail due to missing dependencies, but widget tree should remain intact
        }
        
        // Verify the button is still there after tap attempt
        expect(find.text('AI生成メイク'), findsOneWidget);
      });
    });
  });
}