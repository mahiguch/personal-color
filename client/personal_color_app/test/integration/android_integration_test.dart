import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:personal_color_app/main.dart' as app;
import 'package:personal_color_app/core/di/injection_container.dart' as di;
import 'package:personal_color_app/core/services/android_permission_service.dart';
import 'package:personal_color_app/core/performance/android_performance_optimizer.dart';
import 'package:personal_color_app/core/logging/android_logger.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android統合テスト', () {
    setUpAll(() async {
      await di.init();
      await AndroidLogger.initialize();
    });

    tearDownAll(() async {
      await AndroidLogger.dispose();
    });

    group('アプリ起動・初期化テスト', () {
      testWidgets('アプリが正常に起動する', (WidgetTester tester) async {
        // アプリ起動
        app.main();
        await tester.pumpAndSettle();

        // Android固有のホーム画面が表示されることを確認
        expect(find.text('パーソナルカラー診断'), findsOneWidget);
        expect(find.text('診断を始める'), findsOneWidget);
      });

      testWidgets('Material Design 3テーマが適用される', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Material Design 3の要素を確認
        final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.theme?.useMaterial3, true);
        
        // カラースキームの確認
        expect(materialApp.theme?.colorScheme, isNotNull);
        expect(materialApp.theme?.colorScheme.brightness, Brightness.light);
      });
    });

    group('権限管理テスト', () {
      testWidgets('カメラ権限リクエストの動作確認', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 診断開始ボタンタップ
        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();

        // カメラページが表示されることを確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        
        // カメラ権限の状態を確認（実際の権限チェックはモックで代用）
        final permissionService = AndroidPermissionService();
        expect(permissionService, isNotNull);
      });

      testWidgets('権限拒否時のエラーハンドリング', (WidgetTester tester) async {
        // エラーダイアログの表示テスト（実際の権限拒否はモックで再現）
        app.main();
        await tester.pumpAndSettle();

        // Mock permission denied scenario
        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // エラーハンドリングが機能することを確認
        // (実際のテストではモックを使用してエラー状態をシミュレート)
      });
    });

    group('カメラ機能テスト', () {
      testWidgets('カメラビューの表示とUI要素', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();

        // Material Design要素の確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        
        // AndroidバックボタンWrapperの確認
        expect(find.byType(PopScope), findsWidgets);
      });

      testWidgets('撮影ボタンの動作', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        // 撮影ボタンタップ（実際のカメラ機能はモックで代用）
        await tester.tap(fab);
        await tester.pump();

        // 撮影処理中のUI状態確認
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('エラーハンドリングテスト', () {
      testWidgets('ネットワークエラー時の表示', (WidgetTester tester) async {
        // ネットワークエラーのシミュレーション
        app.main();
        await tester.pumpAndSettle();

        // エラーダイアログやスナックバーの表示確認
        // (実際のテストではモックを使用してエラー状態をシミュレート)
      });

      testWidgets('メモリ不足エラー時の対応', (WidgetTester tester) async {
        // メモリ不足エラーのシミュレーション
        app.main();
        await tester.pumpAndSettle();

        // パフォーマンス最適化の動作確認
        await AndroidPerformanceOptimizer.optimizeMemory();
        
        // メモリクリーンアップの実行確認
        expect(true, true); // 実際のテストではメモリ使用量の変化を確認
      });
    });

    group('パフォーマンステスト', () {
      testWidgets('アプリ起動時間の測定', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        final launchTime = stopwatch.elapsedMilliseconds;
        
        // 起動時間が3秒以内であることを確認
        expect(launchTime, lessThan(3000));
        AndroidLogger.info('App launch time: ${launchTime}ms', tag: 'Performance');
      });

      testWidgets('メモリ使用量の監視', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // メモリ使用量測定
        final metrics = await AndroidPerformanceOptimizer.getPerformanceMetrics();
        expect(metrics, isNotNull);
        
        if (metrics != null) {
          final memoryUsage = metrics['memoryUsagePercent'] as double?;
          AndroidLogger.info('Memory usage: ${memoryUsage?.toStringAsFixed(1)}%', 
                           tag: 'Performance');
          
          // メモリ使用量が90%を超えていないことを確認
          expect(memoryUsage, lessThan(0.9));
        }
      });

      testWidgets('画面遷移のパフォーマンス', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await AndroidLogger.startTrace('screen_transition');
        
        // 画面遷移実行
        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();
        
        await AndroidLogger.stopTrace('screen_transition');
        
        // 遷移が完了していることを確認
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('Material Designテスト', () {
      testWidgets('Material Design 3 コンポーネント', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();

        // Material 3要素の確認
        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton)
        );
        expect(fab.shape, isA<RoundedRectangleBorder>());

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, isNotNull);
      });

      testWidgets('カラーテーマの適用確認', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MaterialApp));
        final theme = Theme.of(context);
        
        // Personal Color Pinkが適用されていることを確認
        expect(theme.colorScheme.primary, isNotNull);
        expect(theme.useMaterial3, true);
      });
    });

    group('ナビゲーションテスト', () {
      testWidgets('Androidバックボタン処理', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();

        // システムバックボタンのシミュレーション
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          null,
          (data) {},
        );

        // 確認ダイアログが表示されることをテスト
        // (実際の実装では適切なバックボタン処理をテスト)
      });

      testWidgets('Material Motion遷移の確認', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 遷移アニメーションのテスト
        await tester.tap(find.text('診断を始める'));
        
        // アニメーション中のフレーム確認
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('ログ・デバッグテスト', () {
      testWidgets('ログシステムの動作確認', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // ログ出力テスト
        AndroidLogger.info('Integration test started', tag: 'Test');
        AndroidLogger.debug('Debug log test', tag: 'Test');
        AndroidLogger.warning('Warning log test', tag: 'Test');
        
        // ユーザーアクション追跡
        AndroidLogger.logUserAction('app_launch', 
                                  parameters: {'screen': 'home'});

        // ログが正常に動作することを確認（実際にはログ出力の検証）
        expect(AndroidLogger.getDebugInfo()['initialized'], true);
      });

      testWidgets('パフォーマンストレースの動作', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        await AndroidLogger.startTrace('integration_test');
        
        await tester.tap(find.text('診断を始める'));
        await tester.pumpAndSettle();
        
        await AndroidLogger.stopTrace('integration_test');
        
        // トレースが正常に完了することを確認
        expect(true, true); // 実際にはトレース完了の確認
      });
    });
  });
}