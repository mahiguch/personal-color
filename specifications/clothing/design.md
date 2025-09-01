# 詳細設計書 - 衣料品リコメンド機能

## 1. アーキテクチャ概要

### 1.1 システム構成図

```
┌─────────────────┐    HTTPS    ┌─────────────────┐    API Call   ┌─────────────────┐
│   Flutter iOS   │ ─────────→  │  FastAPI Server │ ──────────→  │  Vertex AI      │
│   Application   │             │  (Clothing API) │             │  (Gemini-2.5)   │
└─────────────────┘             └─────────────────┘             └─────────────────┘
        │                               │
        │                               │
        ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│ Diagnosis Result│             │ Clothing Data   │
│ Page + Fashion  │             │ JSON File       │
│ Recommendation  │             │                 │
│ Page            │             │                 │
└─────────────────┘             └─────────────────┘
```

### 1.2 技術スタック

- **クライアント言語**: Dart 3.0+
- **クライアントフレームワーク**: Flutter 3.13+
- **対象プラットフォーム**: iOS (iPhone)
- **サーバー言語**: Python 3.11+
- **サーバーフレームワーク**: FastAPI
- **AI**: Vertex AI Gemini-2.5-pro
- **データ形式**: JSON
- **通信プロトコル**: HTTPS/REST API

## 2. コンポーネント設計

### 2.1 コンポーネント一覧

| コンポーネント名 | 責務 | 依存関係 |
|---|---|---|
| **ClothingRecommendationPage** | 衣料品推奨ページUI | ClothingRecommendationProvider |
| **ClothingRecommendationProvider** | 状態管理・API通信 | GetClothingRecommendations |
| **GetClothingRecommendations** | 衣料品推奨データ取得ユースケース | ClothingRepository |
| **ClothingRepository** | データアクセス抽象化 | ClothingRemoteDataSource |
| **ClothingRemoteDataSource** | API通信実装 | ApiClient |
| **ClothingEndpoint** | サーバーエンドポイント | GeminiService |
| **ClothingProduct** | 衣料品商品エンティティ | - |
| **ClothingRecommendation** | 推奨データエンティティ | ClothingProduct |

### 2.2 各コンポーネントの詳細

#### 2.2.1 ClothingRecommendationPage
- **目的**: 衣料品推奨UIの表示
- **公開インターフェース**:
  ```dart
  class ClothingRecommendationPage extends StatefulWidget {
    final PersonalColorType personalColorType;
  }
  ```
- **内部実装方針**: 
  - TabBarView を使用してカテゴリタブ実装
  - 既存 MakeupRecommendationPage の構造を踏襲
  - ClothingProductCard でグリッド表示

#### 2.2.2 ClothingRecommendationProvider
- **目的**: 状態管理とビジネスロジック
- **公開インターフェース**:
  ```dart
  class ClothingRecommendationProvider extends ChangeNotifier {
    ClothingRecommendation? get recommendation;
    bool get isLoading;
    String? get errorMessage;
    ClothingCategory get selectedCategory;
    List<ClothingProduct> get selectedCategoryProducts;
    String get selectedCategoryExplanation;
    
    Future<void> loadRecommendations(PersonalColorType type);
    void changeCategory(ClothingCategory category);
  }
  ```

#### 2.2.3 GetClothingRecommendations (UseCase)
- **目的**: 衣料品推奨データ取得ビジネスロジック
- **公開インターフェース**:
  ```dart
  class GetClothingRecommendations implements UseCase<ClothingRecommendation, GetClothingRecommendationsParams> {
    Future<Either<Failure, ClothingRecommendation>> call(GetClothingRecommendationsParams params);
  }
  ```

#### 2.2.4 ClothingRepository
- **目的**: データアクセス層の抽象化
- **公開インターフェース**:
  ```dart
  abstract class ClothingRepository {
    Future<ClothingRecommendation> getClothingRecommendations(PersonalColorType personalColorType);
  }
  ```

#### 2.2.5 ClothingRemoteDataSource
- **目的**: API通信の実装
- **公開インターフェース**:
  ```dart
  abstract class ClothingRemoteDataSource {
    Future<ClothingRecommendationModel> getClothingRecommendations(PersonalColorType personalColorType);
  }
  ```

## 3. データフロー

### 3.1 データフロー図

```
診断結果ページ
    ↓ ボタンタップ
ClothingRecommendationPage
    ↓ initState()
ClothingRecommendationProvider.loadRecommendations()
    ↓
GetClothingRecommendations.call()
    ↓
ClothingRepository.getClothingRecommendations()
    ↓
ClothingRemoteDataSource.getClothingRecommendations()
    ↓
HTTP GET /api/v1/clothing-recommendations/{type}
    ↓
ClothingEndpoint.get_clothing_recommendations()
    ↓
get_ai_explanations() → Vertex AI
    ↓
ClothingRecommendationResponse
    ↓
UI更新 (商品表示 + AI説明)
```

### 3.2 データ変換

#### 3.2.1 API → Domain Entity
```dart
// API Response
ClothingRecommendationModel (Data Layer)
    ↓
ClothingRecommendation (Domain Entity)

// 商品データ
ClothingProductModel (Data Layer)
    ↓  
ClothingProduct (Domain Entity)
```

#### 3.2.2 UI状態管理
```dart
// Provider State
ClothingRecommendationProvider
  ├── _recommendation: ClothingRecommendation?
  ├── _isLoading: bool
  ├── _errorMessage: String?
  └── _selectedCategory: ClothingCategory
```

## 4. APIインターフェース

### 4.1 内部API (Clean Architecture)

#### 4.1.1 Repository Interface
```dart
abstract class ClothingRepository {
  Future<ClothingRecommendation> getClothingRecommendations(
    PersonalColorType personalColorType
  );
}
```

#### 4.1.2 UseCase Interface
```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class GetClothingRecommendationsParams extends Equatable {
  final PersonalColorType personalColorType;
  final bool forceRefresh;
  
  const GetClothingRecommendationsParams({
    required this.personalColorType,
    this.forceRefresh = false,
  });
}
```

### 4.2 外部API (Server)

#### 4.2.1 RESTエンドポイント
```python
@router.get(
    "/clothing-recommendations/{personal_color_type}",
    response_model=ClothingRecommendationResponse,
)
async def get_clothing_recommendations(
    personal_color_type: str, 
    request: Request
):
```

#### 4.2.2 レスポンスモデル
```python
class ClothingProduct(BaseModel):
    id: str
    name: str
    brand: str
    category: str
    price: int
    image_url: str
    amazon_url: str
    description: str
    colors: list[str]

class ClothingRecommendationResponse(BaseModel):
    personal_color_type: str
    categories: Dict[str, list[ClothingProduct]]
    ai_explanations: Dict[str, str]
    request_id: str
    timestamp: str
```

## 5. エラーハンドリング

### 5.1 エラー分類

#### 5.1.1 クライアント側エラー
- **NetworkFailure**: ネットワーク接続エラー
- **ServerFailure**: サーバーエラー（500系）
- **DataFailure**: データ解析エラー
- **ValidationFailure**: パラメータ検証エラー

#### 5.1.2 サーバー側エラー
- **400 Bad Request**: 不正なpersonal_color_type
- **404 Not Found**: 該当するデータが見つからない
- **500 Internal Server Error**: サーバー内部エラー
- **503 Service Unavailable**: AI サービス利用不可

### 5.2 エラー通知

#### 5.2.1 ユーザー向けメッセージ
```dart
String getErrorMessage(Failure failure) {
  switch (failure.runtimeType) {
    case NetworkFailure:
      return 'インターネット接続を確認してください';
    case ServerFailure:
      return 'サーバーエラーが発生しました';
    case DataFailure:
      return 'データの読み込みに失敗しました';
    default:
      return '予期しないエラーが発生しました';
  }
}
```

#### 5.2.2 ログ出力（サーバー）
```python
logger.error(
    f"[CLOTHING_API_ERROR] request_id={request_id}, "
    f"error_type={error_type}, "
    f"detail={error_detail}"
)
```

## 6. セキュリティ設計

### 6.1 入力検証

#### 6.1.1 パーソナルカラー検証
```python
def validate_personal_color_type(color_type: str) -> str:
    return SecurityValidator.validate_personal_color_type(color_type)
```

#### 6.1.2 AI生成内容検証
```python
def validate_ai_explanation(content: str) -> str:
    return SecurityValidator.validate_ai_explanation(content)
```

### 6.2 データ保護

#### 6.2.1 URLサニタイゼーション
```python
def validate_amazon_url(url: str) -> bool:
    return url.startswith("https://amazon.co.jp/") or url.startswith("https://www.amazon.co.jp/")
```

## 7. テスト設計

### 7.1 テスト戦略
- **Unit Test**: 各コンポーネントの単体テスト
- **Integration Test**: API通信テスト
- **Widget Test**: UI コンポーネントテスト
- **E2E Test**: 機能全体のテスト

### 7.2 テスト対象

#### 7.2.1 クライアント側
```dart
// Unit Tests
test('ClothingRecommendationProvider should load recommendations', () {});
test('GetClothingRecommendations should return valid data', () {});
test('ClothingRepository should handle network errors', () {});

// Widget Tests  
testWidgets('ClothingRecommendationPage should display products', (tester) {});
testWidgets('ClothingProductCard should handle tap events', (tester) {});
```

#### 7.2.2 サーバー側
```python
# API Tests
def test_get_clothing_recommendations_success():
def test_get_clothing_recommendations_invalid_type():
def test_get_clothing_recommendations_server_error():

# AI Service Tests  
def test_generate_clothing_explanation():
def test_ai_explanation_fallback():
```

## 8. パフォーマンス最適化

### 8.1 想定される負荷
- **同時ユーザー**: 100人
- **レスポンス時間**: 3秒以内
- **メモリ使用量**: 50MB以下（クライアント）

### 8.2 最適化方針

#### 8.2.1 キャッシュ戦略
```python
# Server side caching
_clothing_products_cache: Optional[Dict[str, Any]] = None

def get_clothing_products() -> Dict[str, Any]:
    global _clothing_products_cache
    if _clothing_products_cache is None:
        _clothing_products_cache = load_clothing_products()
    return _clothing_products_cache
```

#### 8.2.2 画像最適化
```dart
// Client side image loading
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 200,
  memCacheHeight: 200,
)
```

## 9. デプロイメント

### 9.1 デプロイ構成

#### 9.1.1 サーバーサイド
```yaml
# server/clothing_endpoint.py
clothing_router = APIRouter(prefix="/api/v1", tags=["clothing"])

# server/main.py  
app.include_router(clothing_router)
```

#### 9.1.2 クライアントサイド
```dart
// Dependency Injection
sl.registerLazySingleton<ClothingRepository>(() => ClothingRepositoryImpl(
  remoteDataSource: sl(),
));

sl.registerLazySingleton<GetClothingRecommendations>(() => GetClothingRecommendations(
  repository: sl(),
));
```

### 9.2 設定管理

#### 9.2.1 環境変数
```python
# API Configuration
CLOTHING_DATA_PATH = os.getenv("CLOTHING_DATA_PATH", "data/clothing_products.json")
GEMINI_AI_MODEL = os.getenv("GEMINI_AI_MODEL", "gemini-2.5-pro")
```

#### 9.2.2 アプリ設定
```dart
// Client Configuration  
class ApiConfig {
  static const String clothingEndpoint = "/api/v1/clothing-recommendations";
  static const Duration requestTimeout = Duration(seconds: 30);
}
```

## 10. 実装上の注意事項

### 10.1 既存コードとの整合性
- **ファイル構造**: makeup機能のディレクトリ構造を踏襲
- **命名規則**: ClothingXxx の prefix を使用
- **デザインパターン**: Clean Architecture + Provider パターン
- **エラーハンドリング**: 既存のFailureクラスを継承

### 10.2 拡張性の考慮
- **Amazon API連携**: 将来的なAPI置換を考慮したインターフェース設計
- **カテゴリ追加**: 新しい商品カテゴリの追加に対応可能な設計
- **国際化**: 多言語対応を見越した文字列管理

### 10.3 保守性
- **ログ**: 適切なログレベルでの出力
- **コメント**: 複雑なロジックへの適切な説明
- **テスト**: 90%以上のカバレッジ目標
- **ドキュメント**: API仕様書とコードドキュメントの同期

## 11. 関連ドキュメント

- `specifications/clothing/requirements.md` - 要件定義書
- `specifications/clothing/tasks.md` - タスク分解書（次に作成）
- `specifications/makeup/design.md` - 参考：メイクアップ機能設計
- `server/src/api/endpoints/makeup.py` - 参考：既存API実装
- `client/personal_color_app/lib/features/makeup/` - 参考：既存UI実装
