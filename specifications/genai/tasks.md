# 実装タスクリスト: Google Gen AI SDK移行

## プロジェクト概要

Google Cloud Vertex AI SDK (`google-cloud-aiplatform`)から統一SDK (`google-genai`)への一括移行を実行する。

## タスク分解方針

### 優先度設定
- **P0 (必須)**: 基本機能動作に必要
- **P1 (重要)**: 品質・性能に影響
- **P2 (推奨)**: 保守性・改善に貢献

### 依存関係管理
- **Phase 1**: 依存関係・設定変更
- **Phase 2**: コア実装変更
- **Phase 3**: テスト更新
- **Phase 4**: 検証・最終化

## Phase 1: 依存関係・設定変更

### TASK-001: requirements.txt更新
- **優先度**: P0
- **担当**: 実装者
- **工数**: 0.5h
- **内容**:
  ```diff
  # Google Cloud & AI
  - google-cloud-aiplatform>=1.55.0
  + google-genai>=0.5.0
  google-auth==2.23.4
  firebase-admin==6.2.0
  ```
- **成功基準**: 
  - [ ] パッケージインストール成功
  - [ ] 競合エラーなし
- **依存**: なし

### TASK-002: Settings クラス更新
- **優先度**: P0
- **担当**: 実装者  
- **工数**: 1h
- **内容**: `server/src/core/config/settings.py`
  ```python
  class Settings(BaseSettings):
      # 新規追加
      use_vertexai: bool = Field(default=True, description="Vertex AI使用フラグ")
      
      # 既存フィールドは維持
      google_cloud_project: str = Field(default="", description="Google Cloudプロジェクト ID")
      vertex_ai_location: str = Field(default="asia-northeast1", description="Vertex AI リージョン")
  ```
- **成功基準**:
  - [ ] Settings クラス正常初期化
  - [ ] 既存設定値の読み込み確認
- **依存**: TASK-001

### TASK-003: 環境変数設定ファイル更新
- **優先度**: P0
- **担当**: 実装者
- **工数**: 0.5h
- **内容**: 
  - `.env.example` 更新
  - `docker-compose.yaml` 更新
  - `cloudrun-service.yaml` 更新
- **追加環境変数**:
  ```bash
  GOOGLE_GENAI_USE_VERTEXAI=true
  ```
- **成功基準**:
  - [ ] 環境変数設定ファイル更新完了
  - [ ] Docker環境での環境変数認識確認
- **依存**: TASK-002

## Phase 2: コア実装変更

### TASK-004: GeminiService import文変更
- **優先度**: P0
- **担当**: 実装者
- **工数**: 0.5h
- **内容**: `server/src/services/gemini_service.py`
  ```python
  # Before
  import vertexai
  from vertexai.generative_models import GenerativeModel, GenerationConfig
  
  # After
  from google import genai
  from google.genai import types
  ```
- **成功基準**:
  - [ ] import エラーなし
  - [ ] 型アノテーション正常
- **依存**: TASK-001

### TASK-005: GeminiService初期化処理変更
- **優先度**: P0
- **担当**: 実装者
- **工数**: 2h
- **内容**: `_initialize_service` メソッド全面書き換え
  ```python
  def _initialize_service(self):
      try:
          # 環境変数設定
          os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "true"
          os.environ["GOOGLE_CLOUD_PROJECT"] = self.settings.google_cloud_project
          os.environ["GOOGLE_CLOUD_LOCATION"] = self.settings.vertex_ai_location
          
          # クライアント初期化
          self.client = genai.Client()
          
          # 生成設定
          self.generation_config = types.GenerateContentConfig(
              temperature=0.7,
              top_p=0.8,
              top_k=20,
              max_output_tokens=200,
          )
      except Exception as e:
          logger.error(f"Failed to initialize Gemini service: {e}")
          self.client = None
  ```
- **成功基準**:
  - [ ] 初期化処理正常実行
  - [ ] エラー時の適切なハンドリング
  - [ ] ログ出力確認
- **依存**: TASK-004

### TASK-006: API呼び出し処理変更
- **優先度**: P0
- **担当**: 実装者
- **工数**: 3h
- **内容**: 
  - `_call_gemini_sync` メソッド変更
  - `_generate_with_retry` メソッド内API呼び出し部分変更
  - `generate_clothing_explanation` メソッド内API呼び出し部分変更
- **変更内容**:
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
- **成功基準**:
  - [ ] API呼び出し成功
  - [ ] レスポンス形式変更なし
  - [ ] エラーハンドリング正常動作
- **依存**: TASK-005

### TASK-007: エラーハンドリング更新
- **優先度**: P1
- **担当**: 実装者
- **工数**: 1h
- **内容**: 新SDKのエラータイプに対応
  ```python
  from google.genai import errors
  
  try:
      response = self.client.models.generate_content(...)
  except errors.APIError as e:
      logger.warning(f"Gemini API error: {e.code} - {e.message}")
      # フォールバック処理
  except Exception as e:
      logger.warning(f"Gemini generation failed: {e}")
  ```
- **成功基準**:
  - [ ] 新SDKエラーの適切なキャッチ
  - [ ] ログメッセージの一貫性
  - [ ] フォールバック機能継続
- **依存**: TASK-006

### TASK-008: health_check メソッド更新
- **優先度**: P1
- **担当**: 実装者
- **工数**: 1h
- **内容**: ヘルスチェック処理の新SDK対応
- **変更箇所**:
  - クライアント初期化状態チェック
  - テスト生成処理の新SDK対応
- **成功基準**:
  - [ ] ヘルスチェック正常動作
  - [ ] レスポンス形式維持
  - [ ] エラー時の適切な状態返却
- **依存**: TASK-007

## Phase 3: テスト更新

### TASK-009: Unit Test モック更新
- **優先度**: P0
- **担当**: 実装者
- **工数**: 2h
- **内容**: `server/tests/unit/services/gemini/test_gemini_service.py`
- **変更内容**:
  - `mock_vertex_ai` フィクスチャを `mock_genai_client` に変更
  - 新SDKのモックオブジェクト作成
  - テストケース内のアサーション更新
- **成功基準**:
  - [ ] 全Unit Test通過
  - [ ] モックの適切な動作確認
- **依存**: TASK-008

### TASK-010: Unit Test 新規テストケース追加
- **優先度**: P1
- **担当**: 実装者
- **工数**: 2h
- **内容**: 新SDK固有のテストケース追加
- **追加テスト**:
  - 環境変数設定テスト
  - 新SDKエラーハンドリングテスト
  - クライアント初期化失敗テスト
- **成功基準**:
  - [ ] 新規テストケース全通過
  - [ ] コードカバレッジ90%以上維持
- **依存**: TASK-009

### TASK-011: Integration Test 更新
- **優先度**: P1
- **担当**: 実装者
- **工数**: 1.5h
- **内容**: 
  - `test_vertex_gemini.py` → `test_genai_integration.py` リネーム
  - 環境変数設定の追加
  - 初期化処理確認の更新
- **成功基準**:
  - [ ] Integration Test通過（スキップ設定維持）
  - [ ] 実際のGCP環境での動作確認
- **依存**: TASK-010

### TASK-012: E2E Test 互換性確認
- **優先度**: P0
- **担当**: 実装者
- **工数**: 1h
- **内容**: `server/tests/integration/test_e2e_integration.py`
- **確認内容**:
  - 既存E2Eテストの通過確認
  - APIレスポンス形式の変更なし確認
  - パフォーマンス要件(30秒)の確認
- **成功基準**:
  - [ ] 全E2E Test通過
  - [ ] APIインターフェース完全互換
  - [ ] 応答時間要件達成
- **依存**: TASK-011

## Phase 4: 検証・最終化

### TASK-013: Docker環境での動作確認
- **優先度**: P0
- **担当**: 実装者
- **工数**: 1h
- **内容**:
  - Dockerビルド成功確認
  - コンテナ内での初期化確認
  - 環境変数の正常読み込み確認
- **コマンド**:
  ```bash
  cd server
  docker build -t personal-color-server:sdk-migration .
  docker run --env-file .env personal-color-server:sdk-migration
  ```
- **成功基準**:
  - [ ] Dockerビルド成功
  - [ ] コンテナ起動成功
  - [ ] ヘルスエンドポイント200応答
- **依存**: TASK-012

### TASK-014: ローカル開発環境動作確認
- **優先度**: P0
- **担当**: 実装者
- **工数**: 1h
- **内容**:
  - ローカルでの server 起動確認
  - 全APIエンドポイントの動作確認
  - ログ出力の適切性確認
- **確認コマンド**:
  ```bash
  cd server
  python -m uvicorn src.api.main:app --reload
  curl http://localhost:8000/health
  curl http://localhost:8000/api/v1/makeup-recommendations/spring
  ```
- **成功基準**:
  - [ ] サーバー正常起動
  - [ ] 全APIエンドポイント正常応答
  - [ ] エラーログなし
- **依存**: TASK-013

### TASK-015: プロンプトテスト実行確認
- **優先度**: P1
- **担当**: 実装者
- **工数**: 0.5h
- **内容**: `server/run_prompt_test.sh` 実行確認
- **確認項目**:
  - プロンプト生成の正常動作
  - AI応答の品質確認
  - 実行時間の確認
- **成功基準**:
  - [ ] プロンプトテスト正常実行
  - [ ] AI応答品質の維持
  - [ ] 実行時間30秒以内
- **依存**: TASK-014

### TASK-016: パフォーマンステスト実行
- **優先度**: P1
- **担当**: 実装者
- **工数**: 1h
- **内容**: 
  - `server/load-test.py` 実行
  - 応答時間の測定・評価
  - リソース使用量確認
- **成功基準**:
  - [ ] 平均応答時間15秒以内
  - [ ] 最大応答時間30秒以内
  - [ ] メモリ使用量の大幅増加なし
- **依存**: TASK-015

### TASK-017: ドキュメント更新
- **優先度**: P2
- **担当**: 実装者
- **工数**: 1h
- **内容**:
  - `server/README.md` の更新
  - `CLAUDE.md` の開発コマンド更新
  - API例・設定例の更新
- **更新内容**:
  - 新SDK使用の明記
  - 環境変数設定手順
  - トラブルシューティング情報
- **成功基準**:
  - [ ] ドキュメント更新完了
  - [ ] 設定手順の正確性確認
- **依存**: TASK-016

### TASK-018: 最終動作確認・ロールバック準備
- **優先度**: P0
- **担当**: 実装者
- **工数**: 1h
- **内容**:
  - 全機能の最終確認
  - ロールバック手順の確認
  - デプロイメント準備
- **確認項目**:
  - Unit/Integration/E2E Test全通過
  - API Interface完全互換性
  - パフォーマンス要件達成
  - エラーハンドリング正常動作
- **成功基準**:
  - [ ] 全テスト通過
  - [ ] 全機能正常動作確認
  - [ ] ロールバック手順確認完了
- **依存**: TASK-017

## タスク実行スケジュール

### 推奨実行順序

**Day 1**: Phase 1 (基盤整備)
- TASK-001 → TASK-002 → TASK-003

**Day 2**: Phase 2 前半 (コア変更)
- TASK-004 → TASK-005 → TASK-006

**Day 3**: Phase 2 後半 (機能完成)
- TASK-007 → TASK-008

**Day 4**: Phase 3 (テスト更新)
- TASK-009 → TASK-010 → TASK-011 → TASK-012

**Day 5**: Phase 4 (検証・最終化)
- TASK-013 → TASK-014 → TASK-015 → TASK-016 → TASK-017 → TASK-018

### 工数見積もり

- **Phase 1**: 2h
- **Phase 2**: 7.5h  
- **Phase 3**: 6.5h
- **Phase 4**: 5.5h
- **合計**: 21.5h (約3-4日)

## チェックポイント

### Phase 1 完了時
- [ ] 依存関係の正常インストール
- [ ] 設定ファイルの正常読み込み
- [ ] 環境変数の正常認識

### Phase 2 完了時
- [ ] GeminiService クラスの正常初期化
- [ ] API呼び出しの基本動作
- [ ] エラーハンドリングの動作確認

### Phase 3 完了時
- [ ] 全Unit Test通過
- [ ] Integration Test正常動作
- [ ] E2E Test通過（API互換性確認）

### Phase 4 完了時
- [ ] 本番環境相当での動作確認
- [ ] パフォーマンス要件達成
- [ ] ロールバック準備完了

## リスク管理

### 高リスクタスク
- **TASK-005**: 初期化処理変更（コア機能への影響大）
- **TASK-006**: API呼び出し処理変更（動作安定性への影響）
- **TASK-012**: E2E Test（互換性の最終確認）

### リスク軽減策
1. **段階的実装**: 各Phaseでの動作確認を徹底
2. **バックアップ**: 変更前のファイルのバックアップ取得
3. **ロールバック**: 即座に復旧可能な準備を常時維持

## 完了基準

### 必須達成項目
- [ ] 全Unit Test通過 (100%)
- [ ] 全Integration Test通過
- [ ] 全E2E Test通過 (API互換性確認)
- [ ] 応答時間30秒以内達成
- [ ] Docker/ローカル環境での正常動作

### 品質基準  
- [ ] コードカバレッジ90%以上
- [ ] メモリリーク・パフォーマンス劣化なし
- [ ] ログ品質の維持
- [ ] エラーハンドリングの完全性

---

*本タスクリストは、要件定義・技術設計・テスト設計に基づいて作成され、SDK移行の確実な実行を保証する。*