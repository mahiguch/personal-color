# 詳細設計書 - メイクアップ推奨機能

## 1. アーキテクチャ概要

### 1.1 システム構成図

```
[iOS App - Flutter]
├── Presentation層 (features/makeup/presentation/)
│   ├── MakeupRecommendationPage
│   ├── ProductCardWidget  
│   └── MakeupRecommendationProvider
├── Domain層 (features/makeup/domain/)
│   ├── MakeupProduct (Entity)
│   ├── MakeupRecommendation (Entity)
│   ├── MakeupRepository (Abstract)
│   └── GetMakeupRecommendationsUseCase
└── Data層 (features/makeup/data/)
    ├── MakeupRepositoryImpl
    ├── MakeupRemoteDataSource
    └── MakeupProductModel

[Server - Python FastAPI]
├── API エンドポイント
│   └── GET /api/v1/makeup-recommendations/{type}
├── 静的商品データベース (JSON)
└── Gemini AI連携
```

### 1.2 技術スタック

- **言語**: Dart 3.0+ (Flutter), Python 3.11+ (Server)
- **フレームワーク**: Flutter 3.13+, FastAPI
- **状態管理**: provider ^6.0.5
- **HTTP通信**: dio ^5.3.2
- **依存性注入**: get_it ^7.6.4
- **ローカルキャッシュ**: shared_preferences ^2.2.2
- **AI**: Vertex AI Gemini-2.5-pro
- **テスト**: flutter_test, mockito

## 2. コンポーネント設計

### 2.1 コンポーネント一覧

| コンポーネント名 | 責務 | 依存関係 |
|---|---|---|
| MakeupRecommendationPage | メイクアップ推奨画面のUI | MakeupRecommendationProvider |
| ProductCardWidget | 商品カード表示 | MakeupProduct Entity |
| MakeupRecommendationProvider | 推奨データの状態管理 | GetMakeupRecommendationsUseCase |
| MakeupCacheProvider | キャッシュデータ管理 | SharedPreferences |
| GetMakeupRecommendationsUseCase | 推奨データ取得ビジネスロジック | MakeupRepository |
| MakeupRepositoryImpl | データ取得の実装 | MakeupRemoteDataSource |
| MakeupRemoteDataSource | API通信 | Dio |

### 2.2 各コンポーネントの詳細

#### MakeupRecommendationPage (Presentation)
- **目的**: メイクアップ推奨機能のメイン画面
- **公開インターフェース**:
  ```dart
  class MakeupRecommendationPage extends StatelessWidget {
    final PersonalColorType personalColorType;
    const MakeupRecommendationPage({required this.personalColorType});
  }
  ```
- **内部実装方針**: 
  - TabView でカテゴリ分け（アイシャドウ・チーク・リップ）
  - Consumer でProvider データを監視
  - エラー状態・ローディング状態の適切な表示

#### ProductCardWidget (Presentation)
- **目的**: 個別商品情報の表示
- **公開インターフェース**:
  ```dart
  class ProductCardWidget extends StatelessWidget {
    final MakeupProduct product;
    final String aiExplanation;
    const ProductCardWidget({required this.product, required this.aiExplanation});
  }
  ```
- **内部実装方針**: 
  - Material Card デザイン
  - 画像のプログレッシブローディング
  - Amazon URL への確認ダイアログ

#### GetMakeupRecommendationsUseCase (Domain)
- **目的**: 推奨データ取得のビジネスロジック
- **公開インターフェース**:
  ```dart
  class GetMakeupRecommendationsUseCase {
    Future<Either<Failure, MakeupRecommendation>> call(PersonalColorType type);
  }
  ```
- **内部実装方針**: 
  - キャッシュ確認 → API呼び出し → レスポンス変換
  - エラーハンドリング（ネットワーク・API・データ不整合）

## 3. データフロー

### 3.1 データフロー図

```
診断結果ページ
    ↓ 「おすすめのメイク」ボタンタップ
    ↓ (personalColorType をパラメータとして渡す)
MakeupRecommendationPage 初期化
    ↓
MakeupRecommendationProvider.loadRecommendations()
    ↓
GetMakeupRecommendationsUseCase.call(type)
    ↓
MakeupCacheProvider.getCachedData() → キャッシュ確認
    ↓ (キャッシュなし/期限切れ)
MakeupRepositoryImpl.getMakeupRecommendations(type)
    ↓
MakeupRemoteDataSource.fetchRecommendations(type)
    ↓ HTTP Request
Server API: GET /api/v1/makeup-recommendations/{type}
    ↓ 商品データ取得 + Gemini AI説明生成
JSON Response
    ↓
MakeupProductModel → MakeupProduct Entity 変換
    ↓
MakeupCacheProvider.cacheData() → ローカルキャッシュ保存
    ↓
MakeupRecommendationProvider 状態更新
    ↓
UI再描画 (商品カード表示)
```

### 3.2 データ変換

- **入力データ形式**: `PersonalColorType` enum (spring/summer/autumn/winter)
- **処理過程**: API JSON → Model → Entity → UI State
- **出力データ形式**: `MakeupRecommendation` entity (カテゴリ別商品リスト + AI説明)

## 4. APIインターフェース

### 4.1 内部API (モジュール間)

```dart
// Domain Repository Interface
abstract class MakeupRepository {
  Future<Either<Failure, MakeupRecommendation>> getMakeupRecommendations(
    PersonalColorType personalColorType
  );
}

// UseCase Interface  
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
```

### 4.2 外部API (Server)

#### エンドポイント
```
GET /api/v1/makeup-recommendations/{personal_color_type}
```

#### リクエストパラメータ
- `personal_color_type`: string ("spring" | "summer" | "autumn" | "winter")

#### レスポンス形式
```json
{
  "personal_color_type": "spring",
  "categories": {
    "eyeshadow": [
      {
        "id": "eye_001",
        "name": "ナチュラルアイシャドウパレット",
        "brand": "Example Brand",
        "category": "eyeshadow", 
        "price": 1500,
        "image_url": "https://example.com/image1.jpg",
        "amazon_url": "https://amazon.co.jp/...",
        "description": "明るい色合いのパレット",
        "colors": ["コーラルピンク", "ゴールドブラウン", "クリーム"]
      }
    ],
    "cheek": [/* 3商品配列 */],
    "lip": [/* 3商品配列 */]
  },
  "ai_explanations": {
    "eyeshadow": "あなたのSpringタイプには、明るくて温かみのある色がとても似合います。このパレットのコーラルピンクとゴールドブラウンは、あなたの肌の暖かさを引き出してくれます。キラキラしたラメで目元がぱっと明るく見えますよ。",
    "cheek": "Springタイプのあなたには、このピーチカラーのチークがぴったりです。...",
    "lip": "明るいコーラルピンクのリップで、Springタイプの魅力を最大限に..."
  },
  "request_id": "makeup_rec_1640995200000",
  "timestamp": "2021-12-31T15:00:00Z"
}
```

#### エラーレスポンス
```json
{
  "error": {
    "code": "PERSONAL_COLOR_NOT_FOUND",
    "message": "指定されたパーソナルカラータイプが見つかりません",
    "details": {}
  }
}
```

## 5. エラーハンドリング

### 5.1 エラー分類

- **NetworkFailure**: インターネット接続不良
  - 対処: 「インターネットに接続してもう一度お試しください」メッセージ表示
- **ServerFailure**: API サーバーエラー (500系)
  - 対処: 「サーバーで問題が発生しました。もう一度お試しください」メッセージ表示
- **DataFailure**: 商品データ不正・不整合
  - 対処: 「商品データの読み込みに失敗しました。もう一度お試しください」メッセージ表示
- **CacheFailure**: ローカルキャッシュ読み書きエラー
  - 対処: キャッシュを無視してAPI呼び出し続行

### 5.2 エラー通知

- **ユーザー向け表示**: 小学5年生にもわかりやすい日本語メッセージ
- **ログ戦略**: 
  - エラー詳細情報はデバッグ用ログに記録
  - ユーザー操作は匿名化してメトリクス収集
- **リトライ機能**: 「もう一度試す」ボタンで再実行可能

## 6. セキュリティ設計

### 6.1 データ保護

- **ローカルキャッシュ**: 暗号化不要（商品情報は公開データ）
- **API通信**: HTTPS必須
- **画像URL**: 信頼できるドメインからの取得のみ許可

### 6.2 入力検証

- **PersonalColorType**: enum値での厳密なバリデーション
- **API レスポンス**: JSON schema validation
- **商品URL**: Amazon ドメイン確認後の外部リンク許可

## 7. パフォーマンス最適化

### 7.1 想定される負荷

- **同時ユーザー数**: 50-100ユーザー/分
- **API レスポンス時間**: 2秒以内 (95%tile)
- **画像読み込み**: 1秒以内 (Progressive loading)

### 7.2 最適化方針

- **プリフェッチング**: 診断結果表示時に推奨データの事前取得
- **画像最適化**: 
  - WebP形式優先、PNG/JPEGフォールバック
  - サムネイル画像 (200x200) → フル画像の段階的読み込み
  - デバイス容量上限: 50MB (LRU キャッシュ)
- **メモリ管理**: 画面遷移時の適切なリソース解放

## 8. キャッシング戦略

### 8.1 キャッシュ階層

```
Level 1: メモリキャッシュ (AppScope)
- MakeupRecommendationProvider 内
- アプリ起動中のみ有効

Level 2: ローカルストレージ (Persistent)  
- SharedPreferences
- 期限付きキャッシュ

Level 3: 画像キャッシュ (File System)
- デバイスストレージ
- LRU方式で容量管理
```

### 8.2 キャッシュライフサイクル

```dart
// キャッシュキー設計
String cacheKey = "makeup_recommendations_${personalColorType.name}";
String aiCacheKey = "ai_explanations_${personalColorType.name}";
String imageCacheKey = "product_image_${productId}";

// キャッシュ期限
Duration recommendationCacheDuration = Duration(hours: 24);
Duration aiExplanationCacheDuration = Duration(days: 7);  
// 画像キャッシュは無期限（容量管理でLRU削除）
```

## 9. テスト設計

**詳細なテスト設計については、`/test-design`コマンドを実行してテスト設計書を作成してください。**

テスト設計書では以下の内容を定義します：

- **単体テスト**: UseCase・Repository・Provider の正常系・異常系
- **ウィジェットテスト**: ページ・カード・ボタンの表示・タップ動作
- **統合テスト**: API連携・ナビゲーション・キャッシングの動作確認
- **モック戦略**: Gemini API・商品データ・ネットワークレスポンスのモック化

## 10. デプロイメント

### 10.1 デプロイ構成

**クライアント側**:
- iOS App Store での配信 (既存プロセス)
- バージョン番号の適切な更新

**サーバー側**:
- Google Cloud Run での API デプロイ (既存環境)
- 静的商品データの更新プロセス確立

### 10.2 設定管理

```dart
// Environment Configuration
class MakeupConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'MAKEUP_API_BASE_URL',
    defaultValue: 'https://your-api-domain.com',
  );
  
  static const Duration cacheExpiration = Duration(
    hours: int.fromEnvironment('MAKEUP_CACHE_HOURS', defaultValue: 24),
  );
}
```

## 11. 実装上の注意事項

### 11.1 Clean Architecture遵守
- 依存関係の方向を厳密に管理（外側 → 内側のみ）
- Domain層は外部依存を持たない純粋なDartコード
- Presentation層はDomain層のみに依存

### 11.2 既存機能への影響回避
- 診断結果ページの既存レイアウトを崩さないボタン配置
- 既存のナビゲーション構造を変更しない
- 共通UIコンポーネントの一貫性維持

### 11.3 ユーザビリティ
- 小学5年生向けの直感的なUI設計
- エラー状態での適切なユーザーガイダンス
- 外部サイト遷移時の保護者への配慮

### 11.4 データベース構造例

```json
// サーバー側の静的商品データ例
{
  "spring": {
    "eyeshadow": [
      {
        "id": "spring_eye_001",
        "name": "明るいアイシャドウパレット",
        "brand": "ナチュラルコスメ",
        "category": "eyeshadow",
        "price": 1800,
        "image_url": "https://example.com/spring_eye_001.jpg",
        "amazon_url": "https://amazon.co.jp/dp/B08XYZ123",
        "description": "Springタイプ向けの明るく温かい色合い",
        "colors": ["コーラルピンク", "ピーチオレンジ", "ゴールドブラウン"]
      }
      // ... 残り2商品
    ],
    "cheek": [ /* 3商品 */ ],
    "lip": [ /* 3商品 */ ]
  },
  "summer": { /* 同様の構造 */ },
  "autumn": { /* 同様の構造 */ },
  "winter": { /* 同様の構造 */ }
}
```

## 12. マイルストーンと開発フェーズ

### Phase 1: 基盤実装
- Domain層のEntity・UseCase実装
- Data層のRepository・DataSource実装
- 基本的なエラーハンドリング

### Phase 2: UI実装  
- MakeupRecommendationPage実装
- ProductCardWidget実装
- Provider状態管理実装

### Phase 3: API統合
- サーバー側エンドポイント実装
- 静的商品データベース作成
- Gemini AI説明生成実装

### Phase 4: 最適化・テスト
- キャッシング機能実装
- パフォーマンス最適化
- 包括的テスト実装

### Phase 5: 統合・検証
- 既存診断結果ページとの統合
- エンドツーエンドテスト
- ユーザビリティ検証