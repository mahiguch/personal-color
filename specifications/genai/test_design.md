# テスト設計書: Google Gen AI SDK移行

## テスト概要

Google Cloud Vertex AI SDK (`google-cloud-aiplatform`)から統一SDK (`google-genai`)への移行に伴うテスト戦略・仕様を定義する。

## テスト方針

### 基本原則
1. **既存テストの継承**: 現在のテストケース構造・期待値を最大限維持
2. **段階的検証**: Unit → Integration → E2E の順序で検証
3. **回帰防止**: 既存機能の動作保証を最優先
4. **新SDK固有テスト**: 環境変数設定・エラーハンドリングの追加検証

### テスト分類

```
├── Unit Test (単体テスト)
│   ├── GeminiService クラステスト
│   ├── 初期化処理テスト
│   └── API呼び出しテスト
├── Integration Test (統合テスト) 
│   ├── Vertex AI接続テスト
│   ├── プロンプト生成テスト
│   └── キャッシュ機能テスト
└── E2E Test (エンドツーエンドテスト)
    ├── API Interface テスト
    ├── パフォーマンステスト
    └── エラーリカバリテスト
```

## Unit Test (単体テスト) 設計

### 対象ファイル
- `server/tests/unit/services/gemini/test_gemini_service.py`

### 移行前後の比較

#### モック・フィクスチャの変更

**Before (現在)**:
```python
@pytest.fixture
def mock_vertex_ai(self):
    """Mock Vertex AI components"""
    with patch("src.services.gemini.gemini_service.vertexai") as mock_vertexai, \
         patch("src.services.gemini.gemini_service.GenerativeModel") as mock_model_class, \
         patch("src.services.gemini.gemini_service.get_settings") as mock_settings:
        
        # Mock settings
        mock_settings_obj = MagicMock()
        mock_settings_obj.google_cloud_project = "test-project"
        mock_settings_obj.vertex_ai_location = "us-central1"
        mock_settings.return_value = mock_settings_obj
        
        # Mock model
        mock_model = MagicMock()
        mock_model_class.return_value = mock_model
        
        yield {
            "vertexai": mock_vertexai,
            "model_class": mock_model_class,
            "model": mock_model,
            "settings": mock_settings_obj,
        }
```

**After (移行後)**:
```python
@pytest.fixture
def mock_genai_client(self):
    """Mock Google Gen AI Client components"""
    with patch("src.services.gemini_service.genai.Client") as mock_client_class, \
         patch("src.services.gemini_service.os.environ", {}) as mock_env, \
         patch("src.services.gemini_service.get_settings") as mock_settings:
        
        # Mock settings
        mock_settings_obj = MagicMock()
        mock_settings_obj.google_cloud_project = "test-project"
        mock_settings_obj.vertex_ai_location = "us-central1"
        mock_settings_obj.gemini_model_name = "gemini-1.5-flash"
        mock_settings.return_value = mock_settings_obj
        
        # Mock client
        mock_client = MagicMock()
        mock_client.models = MagicMock()
        mock_client_class.return_value = mock_client
        
        yield {
            "client_class": mock_client_class,
            "client": mock_client,
            "settings": mock_settings_obj,
            "env": mock_env,
        }
```

### テストケース仕様

#### TC-U001: GeminiService初期化テスト

**目的**: 環境変数による自動初期化の検証

```python
def test_gemini_service_initialization_with_env_vars(self, mock_genai_client):
    """Test GeminiService initialization with environment variables"""
    # Given: 環境変数が設定されている
    mock_genai_client["env"].update({
        "GOOGLE_GENAI_USE_VERTEXAI": "true",
        "GOOGLE_CLOUD_PROJECT": "test-project",
        "GOOGLE_CLOUD_LOCATION": "us-central1"
    })
    
    # When: GeminiServiceを初期化
    service = GeminiService()
    
    # Then: 正常に初期化される
    assert service is not None
    assert service.client is not None
    assert hasattr(service, 'generate_makeup_explanation')
    assert hasattr(service, 'generate_clothing_explanation')
    assert hasattr(service, 'health_check')
    
    # 環境変数が正しく設定されたことを確認
    mock_genai_client["client_class"].assert_called_once()
```

#### TC-U002: API呼び出し成功テスト

**目的**: 新SDKでのAPI呼び出し処理検証

```python
@pytest.mark.asyncio
async def test_generate_makeup_explanation_success(self, mock_genai_client):
    """Test successful makeup explanation generation with new SDK"""
    # Given: モックレスポンス設定
    mock_response = MagicMock()
    mock_response.text = "春タイプの方には明るい色合いがお似合いです"
    mock_genai_client["client"].models.generate_content.return_value = mock_response
    
    # Mock validation
    mock_prompt_generator = MagicMock()
    mock_prompt_generator.validate_ai_response.return_value = True
    
    service = GeminiService()
    service.makeup_prompt_generator = mock_prompt_generator
    
    # テストデータ
    test_products = [
        MakeupProduct(
            id="test", name="テスト", brand="テスト", category="eyeshadow",
            price=1000, description="テスト", colors=["ピンク"]
        )
    ]
    
    # When: メイクアップ説明生成を実行
    result = await service.generate_makeup_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
    )
    
    # Then: 成功結果が返される
    assert result.success is True
    assert result.response is not None
    assert result.response.content == "春タイプの方には明るい色合いがお似合いです"
    assert result.response.model_used == "gemini-1.5-flash"
    assert result.response.is_fallback is False
```

#### TC-U003: API呼び出し失敗・フォールバック テスト

**目的**: エラー時のフォールバック機能検証

```python
@pytest.mark.asyncio
async def test_api_error_fallback(self, mock_genai_client):
    """Test fallback mechanism when API fails"""
    # Given: API呼び出しがエラー
    from google.genai import errors
    mock_genai_client["client"].models.generate_content.side_effect = errors.APIError("API Error")
    
    # Mock fallback
    mock_prompt_generator = MagicMock()
    mock_prompt_generator.get_fallback_explanation.return_value = "フォールバック説明"
    
    service = GeminiService()
    service.makeup_prompt_generator = mock_prompt_generator
    
    test_products = [MakeupProduct(...)]  # テストデータ
    
    # When: API呼び出し実行
    result = await service.generate_makeup_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
    )
    
    # Then: フォールバック結果が返される
    assert result.success is True
    assert result.response.content == "フォールバック説明"
    assert result.response.model_used == "fallback"
    assert result.response.is_fallback is True
```

#### TC-U004: キャッシュ機能テスト

**目的**: キャッシュ機能の動作継続検証

```python
@pytest.mark.asyncio
async def test_cache_functionality_maintained(self, mock_genai_client):
    """Test that caching functionality is maintained after SDK migration"""
    # Given: 初回呼び出し用モック
    mock_response = MagicMock()
    mock_response.text = "キャッシュテスト用レスポンス"
    mock_genai_client["client"].models.generate_content.return_value = mock_response
    
    service = GeminiService()
    # キャッシュクリア
    service.clear_cache()
    
    test_products = [MakeupProduct(...)]
    
    # When: 初回呼び出し
    result1 = await service.generate_makeup_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
    )
    
    # When: 同じパラメータで再呼び出し
    result2 = await service.generate_makeup_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
    )
    
    # Then: 2回目はキャッシュヒット
    assert result1.success is True
    assert result2.success is True
    assert result2.response.model_used == "cached"
    
    # API呼び出しは1回のみ
    assert mock_genai_client["client"].models.generate_content.call_count == 1
```

### 追加テストケース

#### TC-U005: 環境変数設定不備テスト

```python
def test_missing_environment_variables(self, mock_genai_client):
    """Test handling of missing environment variables"""
    # Given: 環境変数未設定
    mock_genai_client["env"].clear()
    
    # When: GeminiService初期化
    service = GeminiService()
    
    # Then: 適切にハンドリングされる（クライアント未初期化状態）
    assert service.client is None
```

#### TC-U006: 新SDKエラーハンドリング テスト

```python
@pytest.mark.asyncio
async def test_new_sdk_error_handling(self, mock_genai_client):
    """Test error handling specific to new SDK"""
    from google.genai import errors
    
    # Given: 新SDK特有のエラー
    mock_genai_client["client"].models.generate_content.side_effect = errors.APIError(
        code=400, message="Invalid request"
    )
    
    service = GeminiService()
    test_products = [MakeupProduct(...)]
    
    # When: API呼び出し
    result = await service.generate_makeup_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
    )
    
    # Then: フォールバックまたは適切なエラーハンドリング
    assert result.success is True  # フォールバック成功
    assert result.response.is_fallback is True
```

## Integration Test (統合テスト) 設計

### 対象ファイル
- `server/tests/integration/test_gemini_integration.py`
- `server/tests/unit/services/test_vertex_gemini.py` (リネーム)

### 移行対応仕様

#### TC-I001: Vertex AI接続テスト

**目的**: 新SDKでのVertex AI接続確認

```python
@pytest.mark.skip(reason="Requires Google Cloud credentials - fails in CI")
def test_vertex_ai_connection_with_new_sdk():
    """Test Vertex AI connection using new Google Gen AI SDK"""
    async def _test():
        # Given: 環境変数設定
        os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "true"
        os.environ["GOOGLE_CLOUD_PROJECT"] = os.getenv("GOOGLE_CLOUD_PROJECT", "")
        os.environ["GOOGLE_CLOUD_LOCATION"] = "asia-northeast1"
        
        # When: GeminiService初期化・ヘルスチェック
        service = get_gemini_service()
        health = await service.health_check()
        
        # Then: 接続成功
        assert health["status"] in ["healthy", "degraded"]
        assert health["initialized"] is True
        
    asyncio.run(_test())
```

#### TC-I002: プロンプト生成・レスポンス検証テスト

**目的**: 実際のAI呼び出しでの動作確認

```python
@pytest.mark.skip(reason="Requires Google Cloud credentials - fails in CI")
def test_end_to_end_ai_generation():
    """Test complete AI generation flow with new SDK"""
    async def _test():
        service = get_gemini_service()
        
        test_products = [
            MakeupProduct(
                id="integration_test_001",
                name="統合テスト用アイシャドウ",
                brand="テストブランド",
                category="eyeshadow",
                price=1500,
                description="統合テスト用商品",
                colors=["ピンク", "ベージュ"]
            )
        ]
        
        # When: 実際のAI生成実行
        result = await service.generate_makeup_explanation(
            PersonalColorType.SPRING, MakeupCategory.EYESHADOW, test_products
        )
        
        # Then: 適切なレスポンス
        assert result.success is True
        assert result.response is not None
        assert len(result.response.content) >= 50
        assert len(result.response.content) <= 200
        assert result.response.response_time_ms <= 30000  # 30秒以内
        
    asyncio.run(_test())
```

## E2E Test (エンドツーエンドテスト) 設計

### 対象ファイル
- `server/tests/integration/test_e2e_integration.py`

### 既存テストの継続仕様

#### TC-E001: APIインターフェース互換性テスト

**目的**: クライアントアプリから見たAPI動作の変更なし確認

```python
def test_api_interface_compatibility(self):
    """Test that API interface remains unchanged after SDK migration"""
    # Given: 既存のAPIエンドポイント
    personal_color_types = ["spring", "summer", "autumn", "winter"]
    
    for color_type in personal_color_types:
        # When: APIリクエスト実行
        response = requests.get(
            f"{self.base_url}/api/v1/makeup-recommendations/{color_type}",
            timeout=30  # 30秒タイムアウト
        )
        
        # Then: レスポンス形式確認
        assert response.status_code == 200
        data = response.json()
        
        # 既存フィールドの存在確認
        required_fields = [
            "personal_color_type", 
            "categories", 
            "ai_explanations",
            "request_id", 
            "timestamp"
        ]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # カテゴリ数確認
        assert "eyeshadow" in data["categories"]
        assert "cheek" in data["categories"]
        assert "lip" in data["categories"]
        
        # AI説明文の品質確認
        for category, explanation in data["ai_explanations"].items():
            assert isinstance(explanation, str)
            assert len(explanation) >= 50
            assert len(explanation) <= 200
```

#### TC-E002: パフォーマンス継続テスト

**目的**: 応答時間30秒以内の要件確認

```python
def test_performance_requirements_met(self):
    """Test that performance requirements are met with new SDK"""
    response_times = []
    
    for i in range(10):
        start_time = time.time()
        
        response = requests.get(
            f"{self.base_url}/api/v1/makeup-recommendations/spring",
            timeout=35  # 30秒要件 + 5秒マージン
        )
        
        response_time = int((time.time() - start_time) * 1000)
        response_times.append(response_time)
        
        assert response.status_code == 200
        assert response_time <= 30000  # 30秒以内
    
    # 統計確認
    avg_response_time = sum(response_times) / len(response_times)
    max_response_time = max(response_times)
    
    logger.info(f"Average response time: {avg_response_time:.0f}ms")
    logger.info(f"Max response time: {max_response_time}ms")
    
    assert max_response_time <= 30000
    assert avg_response_time <= 15000  # 平均15秒以内を目標
```

#### TC-E003: キャッシュ性能テスト

**目的**: キャッシュ機能による性能向上確認

```python
def test_cache_performance_maintained(self):
    """Test that cache performance is maintained"""
    # 初回リクエスト（キャッシュミス）
    start_time = time.time()
    response1 = requests.get(
        f"{self.base_url}/api/v1/makeup-recommendations/spring",
        timeout=30
    )
    first_response_time = int((time.time() - start_time) * 1000)
    
    # 2回目リクエスト（キャッシュヒット期待）
    start_time = time.time()
    response2 = requests.get(
        f"{self.base_url}/api/v1/makeup-recommendations/spring",
        timeout=30
    )
    second_response_time = int((time.time() - start_time) * 1000)
    
    # レスポンス確認
    assert response1.status_code == 200
    assert response2.status_code == 200
    
    data1 = response1.json()
    data2 = response2.json()
    
    # コンテンツ一致確認（request_id, timestamp除く）
    data1_clean = {k: v for k, v in data1.items() if k not in ["request_id", "timestamp"]}
    data2_clean = {k: v for k, v in data2.items() if k not in ["request_id", "timestamp"]}
    assert data1_clean == data2_clean
    
    # キャッシュによる性能向上確認
    assert second_response_time < first_response_time
    logger.info(f"Cache improvement: {first_response_time}ms -> {second_response_time}ms")
```

## テストデータ管理

### 共通テストデータ

```python
# tests/conftest.py に追加
@pytest.fixture
def standard_test_products():
    """Standard test products for consistency across tests"""
    return [
        MakeupProduct(
            id="test_spring_eyeshadow_001",
            name="スプリングテスト アイシャドウ",
            brand="テストブランド",
            category="eyeshadow",
            price=1500,
            description="明るく華やかな色合い",
            colors=["コーラルピンク", "ゴールド", "クリーム"]
        ),
        # 他のテストデータ...
    ]

@pytest.fixture
def mock_ai_responses():
    """Standard AI response patterns for testing"""
    return {
        PersonalColorType.SPRING: {
            MakeupCategory.EYESHADOW: "春タイプの方には明るく温かみのある色合いがおすすめです。",
            MakeupCategory.CHEEK: "血色感のある自然な仕上がりを演出できます。",
            MakeupCategory.LIP: "フレッシュで健康的な印象を与えます。"
        },
        # 他のパターン...
    }
```

## テスト実行戦略

### CI/CD パイプライン対応

```yaml
# .github/workflows/test-sdk-migration.yml
name: SDK Migration Test

on:
  pull_request:
    paths:
      - 'server/src/services/gemini_service.py'
      - 'server/requirements.txt'
      - 'server/tests/**'

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          cd server
          pip install -r requirements.txt
          pip install -r requirements-test.txt
      - name: Run unit tests
        run: |
          cd server
          pytest tests/unit/ -v --cov=src/services/
      
  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    if: github.event_name == 'push' # PRでは実行しない
    steps:
      - name: Setup Google Cloud credentials
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - name: Run integration tests
        run: |
          cd server
          pytest tests/integration/ -v --tb=short
```

### ローカル開発用テストコマンド

```bash
# server/Makefile に追加
test-unit-migration:
	pytest tests/unit/services/gemini/ -v --cov=src/services/

test-integration-migration:
	pytest tests/integration/test_gemini_integration.py -v

test-e2e-migration:
	pytest tests/integration/test_e2e_integration.py -v

test-migration-all:
	$(MAKE) test-unit-migration
	$(MAKE) test-integration-migration  
	$(MAKE) test-e2e-migration
```

## テスト成功基準

### 必須クリア項目

1. **Unit Tests**: 全テストケース通過 (100%)
2. **Integration Tests**: Vertex AI接続テスト通過
3. **E2E Tests**: API互換性テスト全通過
4. **Performance Tests**: 30秒以内応答時間達成
5. **Cache Tests**: キャッシュ機能正常動作確認

### 品質基準

1. **コードカバレッジ**: 90%以上
2. **応答時間**: 平均15秒以内、最大30秒以内
3. **エラー率**: 1%未満（フォールバック含む成功率99%以上）
4. **キャッシュヒット率**: 同一リクエストで100%

## リスク対応

### 高リスクテスト項目

1. **認証エラー**: GCP認証設定の差異による接続失敗
2. **API互換性**: 新旧SDKのレスポンス差異
3. **パフォーマンス劣化**: 新SDKでの処理時間増加

### 軽減策

1. **段階的テスト**: Unit → Integration → E2E の順序厳守
2. **詳細ログ**: テスト実行時の詳細ログ出力
3. **ロールバック準備**: テスト失敗時の迅速な復旧体制

---

*本テスト設計書は、技術設計書と連携して、SDK移行の品質保証を担保する。*