# 技術設計書: Google Gen AI SDK移行

## プロジェクト概要

Google Cloud Vertex AI SDK (`google-cloud-aiplatform`)から統一SDK (`google-genai`)への移行に関する技術設計を定義する。

## 設計方針

### 基本設計原則
1. **最小変更原則**: 既存のAPIインターフェースを完全維持
2. **一括移行**: 段階的移行ではなく、一度にすべてを移行
3. **フォールバック維持**: AI利用不可時の既存フォールバック機能を保持
4. **テスト駆動**: 既存テストの通過を移行成功の指標とする

### アーキテクチャ変更概要

```
[Before] 現在のアーキテクチャ
├── vertexai.init() → 明示的初期化
├── GenerativeModel → Vertex AI固有クラス
└── get_settings() → 設定値取得

[After] 移行後のアーキテクチャ
├── 環境変数 → 自動初期化
├── genai.Client() → 統一クライアント
└── 環境変数ベース設定 → 直接参照
```

## パッケージ依存関係の変更

### 削除対象

```python
# requirements.txt から削除
google-cloud-aiplatform>=1.55.0
```

### 追加対象

```python
# requirements.txt に追加
google-genai>=0.5.0
```

### インポート文の変更

```python
# Before
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

# After  
from google import genai
from google.genai import types
```

## 設定管理の変更

### 環境変数設定

新しく追加する環境変数:

```bash
# 新規追加
GOOGLE_GENAI_USE_VERTEXAI=true

# 既存活用（server/src/core/config/settings.py）
GOOGLE_CLOUD_PROJECT=<project-id>
VERTEX_AI_LOCATION=<location>  # → GOOGLE_CLOUD_LOCATION として参照
```

### Settings クラスの変更

`server/src/core/config/settings.py` の変更:

```python
class Settings(BaseSettings):
    # 既存フィールドは維持
    google_cloud_project: str = Field(default="", description="Google Cloudプロジェクト ID") 
    vertex_ai_location: str = Field(default="asia-northeast1", description="Vertex AI リージョン")
    
    # 新規追加: 統一SDK用設定
    use_vertexai: bool = Field(default=True, description="Vertex AI使用フラグ")
    
    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8", 
        case_sensitive=False,
        extra="ignore"
    )
```

## GeminiService クラスの設計変更

### 初期化処理の変更

**Before (既存)**:
```python
def _initialize_service(self):
    try:
        # Vertex AI初期化
        vertexai.init(
            project=self.settings.google_cloud_project,
            location=self.settings.vertex_ai_location,
        )
        
        generation_config = GenerationConfig(...)
        self.model = GenerativeModel(...)
    except Exception as e:
        logger.error(f"Failed to initialize Gemini service: {e}")
        self.model = None
```

**After (移行後)**:
```python
def _initialize_service(self):
    try:
        # 環境変数による自動初期化
        os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "true"
        os.environ["GOOGLE_CLOUD_PROJECT"] = self.settings.google_cloud_project
        os.environ["GOOGLE_CLOUD_LOCATION"] = self.settings.vertex_ai_location
        
        self.client = genai.Client()  # 環境変数から自動設定
        
        # 生成設定
        self.generation_config = types.GenerateContentConfig(
            temperature=0.7,
            top_p=0.8,
            top_k=20,
            max_output_tokens=200,
        )
        
        logger.info(f"Gemini client initialized with model: {self.model_name}")
        
    except Exception as e:
        logger.error(f"Failed to initialize Gemini service: {e}")
        self.client = None
```

### API呼び出し処理の変更

**Before (既存)**:
```python
def _call_gemini_sync(self, prompt: str):
    try:
        response = self.model.generate_content(
            prompt,
            stream=False,
        )
        return response
    except Exception as e:
        raise GeminiServiceError(f"Gemini API call failed: {e}")
```

**After (移行後)**:
```python
def _call_gemini_sync(self, prompt: str):
    try:
        response = self.client.models.generate_content(
            model=self.model_name,
            contents=prompt,
            config=self.generation_config,
        )
        return response
    except Exception as e:
        raise GeminiServiceError(f"Gemini API call failed: {e}")
```

### レスポンス処理の変更

既存のレスポンス処理ロジックは基本的に維持、アクセス方法のみ変更:

```python
# Before
if not response or not response.text:
    raise GeminiServiceError("Empty response from Gemini")

# After
if not response or not response.text:
    raise GeminiServiceError("Empty response from Gemini")
    # アクセス方法は同じ
```

## エラーハンドリングの変更

### 例外タイプの対応

```python
# Before
except Exception as e:
    logger.warning(f"Gemini generation failed: {e}")

# After  
from google.genai import errors

try:
    response = self.client.models.generate_content(...)
except errors.APIError as e:
    logger.warning(f"Gemini API error: {e.code} - {e.message}")
except Exception as e:
    logger.warning(f"Gemini generation failed: {e}")
```

## テストコードの設計変更

### モック・フィクスチャの変更

**テストファイル**: `server/tests/unit/services/gemini/test_gemini_service.py`

```python
# Before
@pytest.fixture
def mock_vertexai(mocker):
    mock_init = mocker.patch('vertexai.init')
    mock_model = mocker.patch('vertexai.generative_models.GenerativeModel')
    return mock_init, mock_model

# After
@pytest.fixture
def mock_genai_client(mocker):
    mock_client = mocker.patch('google.genai.Client')
    return mock_client
```

### テストケースの更新方針

1. **既存テストケースの保持**: テスト名・期待値は維持
2. **モックオブジェクトの変更**: 新SDK対応のモック作成
3. **初期化テストの更新**: 環境変数設定のテスト追加

## 設定ファイルの変更

### Docker設定

**Dockerfile** (追加環境変数):
```dockerfile
# 環境変数設定
ENV GOOGLE_GENAI_USE_VERTEXAI=true
ENV GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
ENV GOOGLE_CLOUD_LOCATION=${VERTEX_AI_LOCATION}
```

### Cloud Run設定

**cloudrun-service.yaml** (環境変数追加):
```yaml
env:
  - name: GOOGLE_GENAI_USE_VERTEXAI
    value: "true"
  - name: GOOGLE_CLOUD_PROJECT
    valueFrom:
      secretKeyRef:
        name: google-cloud-project
        key: project-id
  - name: GOOGLE_CLOUD_LOCATION
    value: "asia-northeast1"
```

## データモデルの互換性

### レスポンス構造の維持

既存のAPIレスポンス形式を完全に維持:

```python
# GeminiResponse データクラス - 変更なし
@dataclass
class GeminiResponse:
    content: str
    generated_at: datetime
    response_time_ms: int
    model_used: str
    is_fallback: bool = False

# GenerationResult データクラス - 変更なし
@dataclass  
class GenerationResult:
    success: bool
    response: Optional[GeminiResponse]
    error_message: Optional[str]
    retry_count: int
```

## パフォーマンス考慮事項

### キャッシュ機能の維持

```python
# 既存のキャッシュロジックは完全に維持
def _get_cached_explanation(self, cache_key: str) -> Optional[GeminiResponse]:
    # 変更なし
    
def _cache_explanation(self, cache_key: str, content: str):
    # 変更なし
```

### リトライ・レート制限の維持

```python
# 既存のリトライロジックは完全に維持
async def _generate_with_retry(self, ...):
    for retry in range(self._max_retries):
        try:
            # API呼び出し部分のみ変更
            response = await asyncio.get_event_loop().run_in_executor(
                None, self._call_gemini_sync, prompt
            )
            # 以降の処理は変更なし
```

## セキュリティ考慮事項

### 認証情報の管理

```python
# 既存のGCP認証メカニズムを維持
# IAMロール、サービスアカウントキー等は変更なし
# 新SDKも同じGCP認証を使用
```

## 互換性テスト戦略

### 段階的テストアプローチ

1. **Unit Test**: 各メソッドレベルでの動作確認
2. **Integration Test**: Gemini API実際呼び出しの確認  
3. **E2E Test**: クライアントアプリからのAPI呼び出し確認

### テストデータの一貫性

```python
# 既存テストで使用するプロンプト・期待値は変更しない
test_products = [
    MakeupProduct(
        id="test_spring_eye",
        name="テスト アイシャドウパレット", 
        # ... 既存テストデータ維持
    )
]
```

## ロールバック戦略

### 緊急ロールバック手順

1. **requirements.txt の復元**
2. **環境変数の削除**  
3. **GeminiService の旧バージョン復元**
4. **デプロイメント実行**

```bash
# 緊急時ロールバックコマンド
git revert <migration-commit>
docker build -t personal-color-server:rollback .
gcloud run deploy --image=personal-color-server:rollback
```

## 移行チェックリスト

### 必須確認項目

- [ ] `requirements.txt` のSDK依存関係変更
- [ ] `GeminiService` クラスの全メソッド移行
- [ ] 環境変数設定の追加  
- [ ] 全Unit Testの通過
- [ ] 全Integration Testの通過
- [ ] Docker/Cloud Run設定の更新
- [ ] エラーハンドリングの動作確認
- [ ] キャッシュ機能の動作確認
- [ ] フォールバック機能の動作確認

### 性能確認項目

- [ ] 応答時間が30秒以内
- [ ] キャッシュヒット時の高速応答
- [ ] リトライ機能の正常動作
- [ ] メモリ使用量の確認

## 技術リスク

### 高リスク項目

1. **API互換性**: 新旧SDKのレスポンス形式差異
2. **認証問題**: Vertex AI認証の設定差異
3. **エラー形式**: 例外タイプ・メッセージの変更

### 軽減策

1. **段階的検証**: Unit → Integration → E2E テスト
2. **詳細ログ**: 移行過程での詳細ログ出力
3. **ロールバック準備**: 即座に復旧可能な準備

---

*本設計書は、要件定義書に基づいて作成されており、実装フェーズでの詳細な技術判断の指針となる。*