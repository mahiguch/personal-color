# テスト設計書 - メイクアップ推奨機能

## 1. テスト概要

### 1.1 テスト目的

- メイクアップ推奨機能の品質保証と信頼性確保
- 小学5年生ユーザーにとって安全で使いやすい機能の提供
- 既存診断機能への影響がないことの確認
- パフォーマンス・セキュリティ要件の達成確認

### 1.2 テスト範囲

**対象**:
- `features/makeup/` モジュール全体
- 診断結果ページの拡張部分（「おすすめのメイク」ボタン）
- サーバー側 `/api/v1/makeup-recommendations` エンドポイント
- キャッシング機能・エラーハンドリング

**対象外**:
- 既存診断機能の詳細テスト（回帰テストのみ）
- Amazon Product Advertising API統合（将来実装）
- Android版実装

### 1.3 テスト環境

- **開発環境**: iOS Simulator (iPhone 14 Pro, iPad 10th generation)
- **実機テスト**: iPhone 13 mini, iPhone 14 Pro Max
- **サーバー環境**: ローカル開発サーバー、ステージング環境
- **依存関係**: MockIto でのモック化、テスト専用商品データ

## 2. テストケース設計

### 2.1 GetMakeupRecommendationsUseCaseのテストケース

#### 2.1.1 正常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T001 | Spring タイプの推奨取得 | PersonalColorType.spring | Spring用商品データ+AI説明を含むMakeupRecommendation | High |
| T002 | Summer タイプの推奨取得 | PersonalColorType.summer | Summer用商品データ+AI説明を含むMakeupRecommendation | High |
| T003 | Autumn タイプの推奨取得 | PersonalColorType.autumn | Autumn用商品データ+AI説明を含むMakeupRecommendation | High |
| T004 | Winter タイプの推奨取得 | PersonalColorType.winter | Winter用商品データ+AI説明を含むMakeupRecommendation | High |
| T005 | キャッシュからのデータ取得 | 期限内キャッシュ存在時 | API呼び出しなしでキャッシュデータ返却 | High |

#### 2.1.2 異常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T101 | ネットワークエラー時 | 接続不良状態 | NetworkFailure返却 | High |
| T102 | サーバーエラー時 | HTTP 500エラー | ServerFailure返却 | High |
| T103 | 不正なJSONレスポンス | 壊れたJSONデータ | DataFailure返却 | High |
| T104 | 空の商品データ | 商品配列が空 | DataFailure返却 | Medium |
| T105 | キャッシュ読み込み失敗 | SharedPreferencesエラー | API呼び出しにフォールバック | Low |

#### 2.1.3 境界値テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T201 | キャッシュ期限切れ直前 | 期限1秒前のキャッシュ | キャッシュデータ使用 | Medium |
| T202 | キャッシュ期限切れ直後 | 期限1秒後のキャッシュ | API呼び出し実行 | Medium |
| T203 | 最大商品数 | 各カテゴリ3商品 | 3商品全て正常表示 | Medium |
| T204 | 最大価格商品 | 価格2000円の商品 | 正常表示 | Low |

### 2.2 MakeupRecommendationProviderのテストケース

#### 2.2.1 正常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T301 | 初期状態 | Provider作成時 | isLoading=false, data=null, error=null | High |
| T302 | データ読み込み開始 | loadRecommendations()呼び出し | isLoading=true状態遷移 | High |
| T303 | データ読み込み成功 | 正常なAPI レスポンス | isLoading=false, data設定, error=null | High |
| T304 | 選択カテゴリ変更 | setSelectedCategory(cheek) | selectedCategory更新、UI再描画 | Medium |
| T305 | リフレッシュ機能 | refresh()呼び出し | キャッシュクリア、API再呼び出し | Medium |

#### 2.2.2 異常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T401 | API呼び出し失敗 | ネットワークエラー | isLoading=false, error設定, データ=null | High |
| T402 | 複数回連続呼び出し | loadRecommendations()連続実行 | 2回目以降は無視、1回のAPI呼び出しのみ | Medium |
| T403 | disposed状態での更新 | dispose後のnotifyListeners | エラーを発生させない | Low |

### 2.3 MakeupRecommendationPageのテストケース

#### 2.3.1 正常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T501 | ページ初期表示 | Spring personalColorType | タイトルに「Spring」表示、3タブ存在 | High |
| T502 | アイシャドウタブ選択 | アイシャドウタブタップ | アイシャドウ商品3件表示 | High |
| T503 | チークタブ選択 | チークタブタップ | チーク商品3件表示 | High |
| T504 | リップタブ選択 | リップタブタップ | リップ商品3件表示 | High |
| T505 | 戻るボタン動作 | 戻るボタンタップ | 診断結果ページへ遷移 | High |
| T506 | ローディング状態表示 | API呼び出し中 | CircularProgressIndicator表示 | Medium |

#### 2.3.2 異常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T601 | エラー状態表示 | API呼び出し失敗 | エラーメッセージ+リトライボタン表示 | High |
| T602 | リトライボタン動作 | リトライボタンタップ | API再呼び出し実行 | High |
| T603 | 空データ状態 | 商品データが空 | 「商品が見つかりません」メッセージ表示 | Medium |

### 2.4 ProductCardWidgetのテストケース

#### 2.4.1 正常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T701 | 商品情報表示 | 完全な商品データ | 画像、名前、ブランド、価格、説明全て表示 | High |
| T702 | Amazonボタンタップ | Amazonボタンタップ | 確認ダイアログ表示 | High |
| T703 | 確認ダイアログOK | ダイアログでOKタップ | Amazon URLを外部ブラウザで開く | High |
| T704 | 確認ダイアログキャンセル | ダイアログでキャンセル | ダイアログ閉じる、URL開かない | High |
| T705 | 画像読み込み成功 | 有効な画像URL | 商品画像正常表示 | Medium |

#### 2.4.2 異常系テスト

| ID | テストケース名 | 入力データ | 期待結果 | 優先度 |
|---|---|---|---|---|
| T801 | 画像読み込み失敗 | 無効な画像URL | プレースホルダー画像表示 | Medium |
| T802 | 長いテキスト表示 | 超長文の商品名・説明 | テキスト適切に省略表示 | Low |
| T803 | 価格未設定 | 価格がnull | 「価格未定」表示 | Low |

### 2.5 統合テストシナリオ

#### シナリオ1: 正常な推奨機能利用フロー

1. **前提条件**: 診断完了済み（Springタイプ）
2. **テスト手順**:
   - Step 1: 診断結果ページで「おすすめのメイク」ボタンタップ
   - Step 2: メイクアップ推奨ページが表示される
   - Step 3: アイシャドウタブでSpring向け商品3件表示確認
   - Step 4: チークタブに切り替え、チーク商品3件表示確認  
   - Step 5: リップタブに切り替え、リップ商品3件表示確認
   - Step 6: 1つの商品の「Amazonで見る」ボタンタップ
   - Step 7: 確認ダイアログでOKタップ
   - Step 8: Amazon商品ページが外部ブラウザで開く
   - Step 9: アプリに戻り、戻るボタンで診断結果ページに戻る
3. **期待結果**: 全ての操作が正常に動作し、ユーザーが迷わず利用できる

#### シナリオ2: エラー発生時のリカバリフロー

1. **前提条件**: ネットワーク接続不良状態
2. **テスト手順**:
   - Step 1: 診断結果ページで「おすすめのメイク」ボタンタップ
   - Step 2: ローディング表示の後、エラーメッセージ表示
   - Step 3: ネットワーク接続を回復
   - Step 4: 「もう一度試す」ボタンタップ
   - Step 5: 正常にデータ読み込み、商品表示
3. **期待結果**: エラー状態から正常状態への復旧が適切に行われる

#### シナリオ3: キャッシュ機能確認フロー

1. **前提条件**: 初回アクセス、キャッシュなし
2. **テスト手順**:
   - Step 1: メイクアップ推奨機能を利用（API呼び出し）
   - Step 2: アプリを一度終了
   - Step 3: アプリ再起動、同じパーソナルカラーでアクセス
   - Step 4: キャッシュからの高速表示を確認
   - Step 5: 24時間後（時刻変更テスト）に再アクセス
   - Step 6: キャッシュ期限切れでAPI再呼び出し確認
3. **期待結果**: キャッシュが適切に機能し、パフォーマンス向上とデータ最新性を両立

## 3. テストデータ設計

### 3.1 マスタデータ

```json
{
  "testData": {
    "valid": {
      "springRecommendation": {
        "personal_color_type": "spring",
        "categories": {
          "eyeshadow": [
            {
              "id": "test_eye_spring_001",
              "name": "テストアイシャドウパレット1",
              "brand": "テストブランドA",
              "category": "eyeshadow",
              "price": 1500,
              "image_url": "https://test-images.com/eye1.jpg",
              "amazon_url": "https://amazon.co.jp/test/eye1",
              "description": "Springタイプ向けテスト商品",
              "colors": ["コーラルピンク", "ゴールドブラウン", "クリーム"]
            }
            // 残り2商品も同様
          ],
          "cheek": [/* 3商品データ */],
          "lip": [/* 3商品データ */]
        },
        "ai_explanations": {
          "eyeshadow": "テスト用AI説明文です。Springタイプのあなたには明るい色が似合います。このパレットで素敵に仕上がりますよ。",
          "cheek": "テスト用チーク説明文...",
          "lip": "テスト用リップ説明文..."
        }
      }
    },
    "invalid": {
      "emptyResponse": {
        "personal_color_type": "spring",
        "categories": {
          "eyeshadow": [],
          "cheek": [],
          "lip": []
        },
        "ai_explanations": {}
      },
      "malformedJson": "{\"invalid\": json syntax}",
      "missingFields": {
        "personal_color_type": "spring"
        // categoriesフィールドなし
      }
    },
    "boundary": {
      "maxPriceProduct": {
        "id": "max_price_001",
        "name": "最大価格テスト商品",
        "price": 2000
        // その他フィールド
      },
      "longTextProduct": {
        "id": "long_text_001", 
        "name": "非常に長い商品名テストデータ".repeat(10),
        "description": "非常に長い説明文テストデータ".repeat(20)
        // その他フィールド
      }
    }
  }
}
```

### 3.2 モックデータ

```dart
// Gemini API モックレスポンス
class MockGeminiService {
  Map<PersonalColorType, Map<String, String>> mockExplanations = {
    PersonalColorType.spring: {
      'eyeshadow': 'Springタイプのあなたには、明るくて温かみのある色がとても似合います...',
      'cheek': 'Springタイプのあなたには、このピーチカラーのチークがぴったり...',
      'lip': '明るいコーラルピンクのリップで、Springタイプの魅力を最大限に...',
    },
    // 他のタイプも同様
  };
}

// ネットワークエラーモック
class MockDioError extends DioException {
  MockDioError() : super(
    requestOptions: RequestOptions(path: '/test'),
    type: DioExceptionType.connectionTimeout,
  );
}
```

## 4. パフォーマンステスト

### 4.1 負荷テスト

- **メイクアップ推奨ページ読み込み時間**: 
  - 目標: 3秒以内 (95%tile)
  - テスト条件: iPhone 13 mini, Wi-Fi環境
  - 測定方法: ボタンタップ → 商品表示完了までの時間

- **API レスポンス時間**:
  - 目標: 2秒以内 (95%tile)  
  - テスト条件: 50並列リクエスト
  - 測定方法: リクエスト送信 → レスポンス受信完了

- **画像読み込み時間**:
  - 目標: 1秒以内 (プログレッシブローディング)
  - テスト条件: 3G回線シミュレート
  - 測定方法: 商品カード表示 → 画像表示完了

### 4.2 ストレステスト

- **最大負荷条件**: 
  - 100並列ユーザー、各5回連続アクセス
  - メモリ使用量100MB以下維持
  - CPU使用率80%以下維持

- **期待される挙動**: 
  - レスポンス時間の劣化5秒以内
  - エラー率5%以下
  - アプリクラッシュ0件

### 4.3 メモリ・ストレージテスト

- **メモリリークテスト**: ページ遷移100回でメモリ増加10MB以下
- **ストレージ使用量**: 画像キャッシュ50MB上限、LRU削除動作確認
- **キャッシュパフォーマンス**: キャッシュヒット時の表示500ms以内

## 5. セキュリティテスト

### 5.1 入力検証テスト

- **パーソナルカラータイプ検証**:
  - 不正な値（"invalid_type"）での APIリクエスト → エラーレスポンス
  - null値での UseCase呼び出し → 適切な例外ハンドリング

- **API レスポンス検証**:
  - 不正なJSONスキーマ → DataFailure発生
  - XSS攻撃ペイロード商品名 → 適切にサニタイズされた表示

- **URL検証**:
  - Amazon以外のドメインURL → 外部リンク無効化
  - JavaScriptスキーム（javascript:alert(1)）→ 無効化

### 5.2 データ保護テスト

- **キャッシュデータ検証**:
  - SharedPreferences内容の確認 → センシティブデータなし
  - ローカルファイルアクセス権限 → アプリサンドボックス内のみ

- **ネットワーク通信テスト**:
  - HTTPS通信確認 → HTTP通信の拒否
  - 証明書検証 → 不正証明書での接続拒否

## 6. テスト実行計画

### 6.1 実行順序

1. **Phase 1: 単体テスト** (推定: 2日間)
   - UseCase テスト (T001-T204)
   - Provider テスト (T301-T403)
   - Widget テスト (T501-T803)

2. **Phase 2: 統合テスト** (推定: 1日間)
   - エンドツーエンドシナリオテスト
   - API統合テスト
   - キャッシング機能テスト

3. **Phase 3: パフォーマンステスト** (推定: 1日間)
   - 負荷テスト・ストレステスト
   - メモリ・ストレージテスト

4. **Phase 4: セキュリティテスト** (推定: 半日)
   - 入力検証・データ保護テスト

5. **Phase 5: 実機テスト** (推定: 1日間)
   - iPhone実機でのユーザビリティテスト
   - 様々なネットワーク環境での動作確認

### 6.2 合格基準

- **カバレッジ**: 90%以上 (単体テスト80%、統合テスト10%以上)
- **全テストケースの合格**: Priority High 100%、Medium 95%以上
- **パフォーマンス基準の達成**: 全ての目標値クリア
- **セキュリティテスト**: 全項目クリア
- **実機テスト**: ユーザビリティ問題なし

### 6.3 テスト環境構築

```dart
// テスト用 DI 設定
void setupTestDI() {
  GetIt.instance.reset();
  
  // モックサービス登録
  GetIt.instance.registerLazySingleton<MakeupRepository>(
    () => MockMakeupRepository(),
  );
  
  GetIt.instance.registerLazySingleton<GeminiService>(
    () => MockGeminiService(),
  );
  
  GetIt.instance.registerLazySingleton<CacheService>(
    () => MockCacheService(),
  );
}

// テスト用 Widget ラッパー
Widget createTestWidget(Widget child) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MakeupRecommendationProvider()),
        ChangeNotifierProvider(create: (_) => MakeupCacheProvider()),
      ],
      child: child,
    ),
  );
}
```

## 7. リスクと対策

| リスク | 影響度 | 発生確率 | 対策 |
|---|---|---|---|
| API応答時間の遅延 | High | Medium | タイムアウト設定、キャッシュ戦略強化 |
| 大量の画像によるメモリ不足 | High | Low | 画像圧縮、LRU キャッシュ実装 |
| テストデータ品質不良 | Medium | Medium | データ検証ツール、レビュープロセス確立 |
| 実機環境差異 | Medium | High | 多種デバイスでの検証、CI/CD統合 |
| パフォーマンス要件未達 | High | Low | 段階的最適化、プロファイリング実施 |

## 8. テスト自動化戦略

### 8.1 自動化対象

- **単体テスト**: 100%自動化（UseCase、Provider、Utility）
- **ウィジェットテスト**: 80%自動化（主要UI コンポーネント）
- **統合テスト**: 50%自動化（APIエンドポイント、主要フロー）
- **パフォーマンステスト**: 70%自動化（API応答時間、メモリ使用量）

### 8.2 CI/CD統合

```yaml
# GitHub Actions 設定例
name: Makeup Feature Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.x'
      
      - name: Get dependencies
        run: flutter pub get
        
      - name: Run unit tests
        run: flutter test --coverage
        
      - name: Run widget tests  
        run: flutter test test/widget/makeup/
        
      - name: Run integration tests
        run: flutter test integration_test/makeup_test.dart
        
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  performance:
    runs-on: macos-latest  
    steps:
      - name: Performance test
        run: flutter test --profile test/performance/
```

### 8.3 テスト実行監視

- **毎日実行**: 回帰テスト（既存機能影響確認）
- **PR毎実行**: 全単体テスト + 主要統合テスト  
- **週次実行**: パフォーマンステスト + セキュリティテスト
- **リリース前**: 全テストスイート + 実機テスト

## 9. テストメトリクス

### 9.1 品質メトリクス

- **欠陥密度**: 機能あたり2件以下
- **テスト効率**: テスト実行時間10分以内（CI環境）
- **カバレッジ推移**: 週次測定、90%以上維持
- **パフォーマンス推移**: リリース毎の応答時間変化測定

### 9.2 レポーティング

- **日次**: テスト実行結果サマリー（Slack通知）
- **週次**: 品質ダッシュボード更新（メトリクス推移）
- **リリース時**: 包括的品質レポート（ステークホルダー向け）

このテスト設計により、メイクアップ推奨機能の高品質な実装と、小学5年生ユーザーにとって安全で使いやすい機能提供を保証します。