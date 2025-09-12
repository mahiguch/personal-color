# AI画像生成メイク機能改修 - テスト設計書

## テスト概要

AI画像生成メイク機能改修に対する包括的なテスト戦略を定義する。クライアント側の UI 改修、カメラ機能変更、サーバー側のAI画像生成機能実装の全てを網羅したテスト設計とする。

## テスト戦略

### テストレベル

1. **単体テスト (Unit Test)**: 個別コンポーネント・メソッドの動作確認
2. **統合テスト (Integration Test)**: コンポーネント間の連携確認
3. **E2Eテスト (End-to-End Test)**: ユーザー視点での完全なフロー確認
4. **API テスト**: サーバー側エンドポイントの動作確認
5. **パフォーマンステスト**: 非機能要件の確認

### テスト方針

- **TDD (Test-Driven Development)**: 新機能は先にテストを書いてから実装
- **回帰テスト**: 既存機能への影響がないことを確認
- **モック・スタブ活用**: 外部依存を排除した確実なテスト
- **自動化優先**: CI/CDパイプラインでの自動実行

## 機能別テスト設計

### FR-1: トップページへのボタン追加

#### 単体テスト

**テスト対象**: `MyHomePage` および `AndroidHomePage`

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| UT-FR1-001 | MyHomePage ウィジェット描画テスト | AI画像生成メイクボタンが表示される | 高 |
| UT-FR1-002 | AndroidHomePage ウィジェット描画テスト | AI画像生成メイクボタンが表示される | 高 |
| UT-FR1-003 | ボタンレイアウトテスト | 診断開始ボタンとの適切な間隔が確保されている | 中 |
| UT-FR1-004 | ボタンスタイリングテスト | テーマに準拠したデザインになっている | 中 |

**テスト実装**:

```dart
// test/features/home/presentation/widgets/test_my_home_page.dart
testWidgets('MyHomePage displays AI makeup button', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyHomePage(title: 'Test'),
    ),
  );

  // AI画像生成メイクボタンの存在確認
  expect(find.text('AI画像生成メイク'), findsOneWidget);
  expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
});

testWidgets('AI makeup button navigation test', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyHomePage(title: 'Test'),
    ),
  );

  // ボタンタップのテスト
  await tester.tap(find.text('AI画像生成メイク'));
  await tester.pumpAndSettle();

  // カメラページに遷移することを確認
  expect(find.byType(CameraPage), findsOneWidget);
});
```

#### 統合テスト

**テスト対象**: トップページからカメラページへの遷移

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| IT-FR1-001 | iOS版遷移テスト | MyHomePage → CameraPage（前面カメラ）の遷移が成功する | 高 |
| IT-FR1-002 | Android版遷移テスト | AndroidHomePage → CameraPage（前面カメラ）の遷移が成功する | 高 |
| IT-FR1-003 | CameraProvider設定テスト | preferFrontCamera=trueでProviderが初期化される | 高 |

### FR-2: カメラのデフォルト表示変更

#### 単体テスト

**テスト対象**: `CameraProvider`

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| UT-FR2-001 | setDefaultCameraToFront(true)テスト | _preferFrontCamera がtrueに設定される | 高 |
| UT-FR2-002 | setDefaultCameraToFront(false)テスト | _preferFrontCamera がfalseに設定される | 高 |
| UT-FR2-003 | initializeCamera前面カメラ優先テスト | 前面カメラが優先的に選択される | 高 |
| UT-FR2-004 | 前面カメラ不在時フォールバックテスト | 前面カメラがない場合は最初のカメラが選択される | 中 |

**テスト実装**:

```dart
// test/features/camera/presentation/providers/test_camera_provider.dart
group('Camera Provider Front Camera Tests', () {
  late CameraProvider cameraProvider;
  late MockInitializeCamera mockInitializeCamera;

  setUp(() {
    mockInitializeCamera = MockInitializeCamera();
    cameraProvider = CameraProvider(mockInitializeCamera);
  });

  test('setDefaultCameraToFront sets preferFrontCamera to true', () {
    // Act
    cameraProvider.setDefaultCameraToFront(true);

    // Assert
    expect(cameraProvider.preferFrontCamera, true);
  });

  test('initializeCamera calls with preferFrontCamera parameter', () async {
    // Arrange
    cameraProvider.setDefaultCameraToFront(true);
    when(mockInitializeCamera.execute(any))
        .thenAnswer((_) async => Right(true));

    // Act
    await cameraProvider.initializeCamera();

    // Assert
    verify(mockInitializeCamera.execute(
      InitializeCameraParams(preferFrontCamera: true)
    )).called(1);
  });
});
```

#### 統合テスト

**テスト対象**: カメラ初期化とハードウェア連携

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| IT-FR2-001 | 前面カメラ選択統合テスト | 実際の前面カメラが起動する | 高 |
| IT-FR2-002 | カメラ切り替え機能テスト | カメラ切り替えボタンが正常に動作する | 中 |
| IT-FR2-003 | 権限要求テスト | カメラ権限要求が正常に行われる | 中 |

### FR-3: AI画像生成画面の表示改修

#### 単体テスト

**テスト対象**: `AIMakeupRecommendationPage`

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| UT-FR3-001 | AI生成画像表示テスト | generated_image が null でない場合、画像が表示される | 高 |
| UT-FR3-002 | パーソナルカラー情報非表示テスト | パーソナルカラー情報が表示されない | 高 |
| UT-FR3-003 | 推薦商品非表示テスト | 推薦商品情報が表示されない | 高 |
| UT-FR3-004 | ローディング表示テスト | isLoading=true時にローディング画面が表示される | 中 |
| UT-FR3-005 | エラー表示テスト | エラー時に適切なエラー画面が表示される | 中 |

**テスト実装**:

```dart
// test/features/makeup/presentation/pages/test_ai_makeup_recommendation_page.dart
testWidgets('AI generated image is displayed when available', (WidgetTester tester) async {
  // Arrange
  final mockProvider = MockAIMakeupRecommendationProvider();
  when(mockProvider.generatedImage).thenReturn('mock_image_url');
  when(mockProvider.isLoading).thenReturn(false);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AIMakeupRecommendationProvider>(
        create: (_) => mockProvider,
        child: AIMakeupRecommendationPage(
          personalColorType: 'spring',
          imageFile: MockFile(),
        ),
      ),
    ),
  );

  // Assert
  expect(find.byType(Image), findsOneWidget);
  expect(find.text('パーソナルカラー'), findsNothing); // パーソナルカラー情報は非表示
});

testWidgets('Loading screen is displayed during image generation', (WidgetTester tester) async {
  // Arrange
  final mockProvider = MockAIMakeupRecommendationProvider();
  when(mockProvider.isLoading).thenReturn(true);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AIMakeupRecommendationProvider>(
        create: (_) => mockProvider,
        child: AIMakeupRecommendationPage(
          personalColorType: 'spring',
          imageFile: MockFile(),
        ),
      ),
    ),
  );

  // Assert
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### FR-4: リロードボタンの削除

#### 単体テスト

**テスト対象**: `AIMakeupRecommendationPage` の AppBar

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| UT-FR4-001 | AppBar actions確認テスト | actions が空または null である | 高 |
| UT-FR4-002 | リロードボタン非存在テスト | refresh アイコンボタンが存在しない | 高 |

**テスト実装**:

```dart
// test/features/makeup/presentation/pages/test_ai_makeup_recommendation_page.dart
testWidgets('AppBar does not have reload button', (WidgetTester tester) async {
  // Arrange
  final mockProvider = MockAIMakeupRecommendationProvider();
  when(mockProvider.isLoading).thenReturn(false);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<AIMakeupRecommendationProvider>(
        create: (_) => mockProvider,
        child: AIMakeupRecommendationPage(
          personalColorType: 'spring',
          imageFile: MockFile(),
        ),
      ),
    ),
  );

  // Assert
  expect(find.byIcon(Icons.refresh), findsNothing);
  
  // AppBarを取得してactionsが空であることを確認
  final AppBar appBar = tester.widget(find.byType(AppBar));
  expect(appBar.actions, isNull);
});
```

### FR-5: サーバー側AI画像生成機能の実装

#### 単体テスト

**テスト対象**: `ImagenService`

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| UT-FR5-001 | _generate_real_makeup_image成功テスト | 正常な画像データが返される | 高 |
| UT-FR5-002 | プロンプト生成テスト | パーソナルカラー別に適切なプロンプトが生成される | 高 |
| UT-FR5-003 | API呼び出し失敗時テスト | ImageGenerationError が適切にスローされる | 高 |
| UT-FR5-004 | モック・本番環境切り替えテスト | client の有無により適切に動作が切り替わる | 中 |

**テスト実装**:

```python
# server/tests/unit/services/test_imagen_service.py
import pytest
from unittest.mock import Mock, AsyncMock
from src.services.imagen_service import ImagenService, ImageGenerationError

class TestImagenService:
    @pytest.fixture
    def mock_client(self):
        mock_client = Mock()
        mock_client.agenerate_content = AsyncMock()
        return mock_client
    
    @pytest.fixture
    def imagen_service(self, mock_client):
        return ImagenService(mock_client)

    @pytest.mark.asyncio
    async def test_generate_makeup_image_success(self, imagen_service, mock_client):
        # Arrange
        mock_response = Mock()
        mock_response.candidates = [Mock()]
        mock_response.candidates[0].content.parts = [Mock()]
        mock_response.candidates[0].content.parts[0].inline_data = Mock()
        mock_response.candidates[0].content.parts[0].inline_data.data = "mock_image_data"
        mock_response.candidates[0].content.parts[0].inline_data.mime_type = "image/jpeg"
        
        mock_client.agenerate_content.return_value = mock_response
        
        # Act
        result = await imagen_service.generate_makeup_image(
            b"mock_image_bytes", "image/jpeg", "spring"
        )
        
        # Assert
        assert result["image_data"] == "mock_image_data"
        assert result["mime_type"] == "image/jpeg"
        assert result["personal_color_type"] == "spring"
        assert result["model_used"] == "imagen-4.0-generate-001"
    
    def test_create_makeup_prompt_spring(self, imagen_service):
        # Act
        prompt = imagen_service._create_makeup_prompt("spring")
        
        # Assert
        assert "明るく暖かい色調" in prompt
        assert "コーラルピンク" in prompt
        assert "小学5年生" in prompt
    
    @pytest.mark.asyncio
    async def test_generate_real_makeup_image_api_error(self, imagen_service, mock_client):
        # Arrange
        mock_client.agenerate_content.side_effect = Exception("API Error")
        
        # Act & Assert
        with pytest.raises(ImageGenerationError):
            await imagen_service._generate_real_makeup_image(
                {"mime_type": "image/jpeg", "data": "mock_data"}, "test prompt"
            )
```

#### API テスト

**テスト対象**: FastAPI エンドポイント `/api/v1/makeup-recommendation`

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| AT-FR5-001 | 正常リクエストテスト | 200 OK、AI生成画像付きレスポンス | 高 |
| AT-FR5-002 | 画像形式不正テスト | 400 Bad Request、適切なエラーメッセージ | 高 |
| AT-FR5-003 | パーソナルカラー不正テスト | 400 Bad Request、適切なエラーメッセージ | 高 |
| AT-FR5-004 | AI生成失敗時テスト | 200 OK、生成画像なしレスポンス | 中 |
| AT-FR5-005 | API制限テスト | 429 Too Many Requests | 中 |

**テスト実装**:

```python
# server/tests/integration/test_ai_makeup_api.py
import pytest
from httpx import AsyncClient
from unittest.mock import patch

@pytest.mark.asyncio
async def test_ai_makeup_recommendation_success(client: AsyncClient):
    # Arrange
    image_data = b"fake_image_data"
    
    with patch('src.services.imagen_service.get_imagen_service') as mock_get_service:
        mock_service = Mock()
        mock_service.generate_makeup_image.return_value = {
            "image_data": "generated_image_data",
            "mime_type": "image/jpeg",
            "generated_at": "2025-09-08T12:00:00Z",
            "model_used": "imagen-4.0-generate-001",
        }
        mock_get_service.return_value = mock_service
        
        # Act
        response = await client.post(
            "/api/v1/makeup-recommendation",
            data={"personal_color_type": "spring"},
            files={"image": ("test.jpg", image_data, "image/jpeg")}
        )
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["personal_color_type"] == "spring"
        assert data["generated_image"] is not None
        assert data["generated_image"]["image_data"] == "generated_image_data"

@pytest.mark.asyncio
async def test_ai_makeup_recommendation_invalid_image_format(client: AsyncClient):
    # Arrange
    image_data = b"fake_text_data"
    
    # Act
    response = await client.post(
        "/api/v1/makeup-recommendation",
        data={"personal_color_type": "spring"},
        files={"image": ("test.txt", image_data, "text/plain")}
    )
    
    # Assert
    assert response.status_code == 400
    assert "サポートされていない画像形式" in response.json()["detail"]
```

## E2Eテスト設計

### E2E-001: 完全なAI画像生成メイクフロー

**テストシナリオ**: トップページからAI画像生成メイクまでの完全フロー

**テストステップ**:
1. アプリを起動
2. トップページでAI画像生成メイクボタンをタップ
3. カメラページで前面カメラが起動していることを確認
4. 写真を撮影
5. AI画像生成画面でローディング表示を確認
6. AI生成画像のみが表示されることを確認（パーソナルカラー・商品情報は非表示）
7. リロードボタンが存在しないことを確認

**期待結果**: 全ステップが正常に完了し、実際のAI生成画像が表示される

**テスト実装**:

```dart
// integration_test/ai_makeup_flow_test.dart
void main() {
  group('AI Makeup Generation E2E Test', () {
    testWidgets('Complete AI makeup flow from homepage', (WidgetTester tester) async {
      // 1. アプリ起動
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      
      // 2. AI画像生成メイクボタンをタップ
      await tester.tap(find.text('AI画像生成メイク'));
      await tester.pumpAndSettle();
      
      // 3. カメラページの表示を確認
      expect(find.byType(CameraPage), findsOneWidget);
      
      // 4. 前面カメラの起動を確認（モック環境では設定確認）
      // Note: 実機テストでは実際のカメラ動作を確認
      
      // 5. 撮影ボタンをタップ
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle(Duration(seconds: 3));
      
      // 6. AI画像生成画面への遷移を確認
      expect(find.byType(AIMakeupRecommendationPage), findsOneWidget);
      
      // 7. ローディング表示の確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // 8. AI生成完了を待つ
      await tester.pumpAndSettle(Duration(seconds: 10));
      
      // 9. AI生成画像のみ表示、他の情報非表示を確認
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('パーソナルカラー'), findsNothing);
      expect(find.text('おすすめ商品'), findsNothing);
      
      // 10. リロードボタンの非存在を確認
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });
}
```

## パフォーマンステスト設計

### 非機能要件テスト

**テスト項目**:

| ID | テスト項目 | 目標値 | 測定方法 |
|----|-----------|--------|----------|
| PT-001 | カメラ起動時間 | 2秒以内 | ストップウォッチ測定 |
| PT-002 | 画面遷移時間 | 1秒以内 | ストップウォッチ測定 |
| PT-003 | AI画像生成時間 | 30秒以内 | API レスポンス測定 |
| PT-004 | メモリ使用量 | 100MB以下増加 | プロファイラ測定 |

**テスト実装**:

```python
# server/tests/performance/test_ai_image_generation_performance.py
import time
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_ai_image_generation_performance(client: AsyncClient):
    # Arrange
    image_data = load_test_image()  # テスト用画像データ
    
    # Act
    start_time = time.time()
    response = await client.post(
        "/api/v1/makeup-recommendation",
        data={"personal_color_type": "spring"},
        files={"image": ("test.jpg", image_data, "image/jpeg")}
    )
    end_time = time.time()
    
    # Assert
    assert response.status_code == 200
    elapsed_time = end_time - start_time
    assert elapsed_time < 30.0, f"AI generation took {elapsed_time}s, expected < 30s"
```

## 回帰テスト設計

### 既存機能影響確認

**テスト対象**:
1. 通常の診断フロー（診断開始ボタン経由）
2. 診断結果画面のレイアウト
3. 既存のメイク推薦機能
4. カメラ機能（通常診断時）

**テストケース一覧**:

| ID | テスト項目 | 期待結果 | 優先度 |
|----|-----------|----------|--------|
| RT-001 | 通常診断フロー確認 | 診断開始→撮影→結果表示が正常動作 | 高 |
| RT-002 | 診断結果画面レイアウト | AI画像生成メイクボタンが削除されている | 高 |
| RT-003 | 既存メイク推薦機能 | おすすめのメイクボタンが正常動作 | 高 |
| RT-004 | カメラのデフォルト設定 | 通常診断では背面カメラが起動 | 中 |

## テスト実行計画

### 段階的テスト実行

1. **Phase 1**: 単体テスト実行
   - 全FR（FR-1～FR-5）の単体テストを実装・実行
   - カバレッジ80%以上を目標

2. **Phase 2**: 統合テスト実行
   - コンポーネント間連携のテストを実行
   - API テストを含む

3. **Phase 3**: E2Eテスト実行
   - 完全なユーザーフローをテスト
   - 実機での動作確認

4. **Phase 4**: パフォーマンス・回帰テスト
   - 非機能要件の確認
   - 既存機能への影響確認

### テスト環境

- **開発環境**: モックデータ・スタブサービス使用
- **ステージング環境**: 実際のImagen APIを使用した統合テスト
- **本番環境**: 限定的な動作確認テスト

### 品質ゲート

各フェーズで以下の品質基準をクリアする必要がある：

- **単体テスト**: カバレッジ80%以上、全テストパス
- **統合テスト**: 全重要パス（Priority高）のテストパス
- **E2Eテスト**: メインフローのテストパス
- **パフォーマンステスト**: 全非機能要件クリア
- **回帰テスト**: 既存機能への影響なし

## テストデータ管理

### テスト用画像データ

```
test_images/
├── spring_sample.jpg      # Spring向けテスト画像
├── summer_sample.jpg      # Summer向けテスト画像  
├── autumn_sample.jpg      # Autumn向けテスト画像
├── winter_sample.jpg      # Winter向けテスト画像
├── no_face_sample.jpg     # 顔が写っていない画像
├── blurry_sample.jpg      # ぼやけた画像
└── invalid_format.txt     # 不正形式ファイル
```

### モックデータ

- **API レスポンス**: 各パーソナルカラー用のモックレスポンス
- **エラーレスポンス**: 各種エラーケース用のレスポンス
- **パフォーマンステスト用**: 大容量画像データ

## 継続的テスト

### CI/CD統合

```yaml
# .github/workflows/ai-makeup-test.yml
name: AI Makeup Feature Test

on:
  pull_request:
    paths:
      - 'client/personal_color_app/lib/features/**'
      - 'server/src/services/imagen_service.py'
      - 'server/src/api/endpoints/makeup.py'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Flutter テスト
      - name: Flutter Test
        run: |
          cd client/personal_color_app
          flutter test
          
      # Python テスト
      - name: Python Test
        run: |
          cd server
          source .venv/bin/activate
          pytest tests/unit/services/test_imagen_service.py -v
          pytest tests/integration/test_ai_makeup_api.py -v
```

---

**作成日**: 2025-09-08  
**作成者**: AI Assistant  
**レビュー**: 未実施  
**承認**: 未実施