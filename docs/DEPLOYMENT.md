# デプロイ手順書（Server / FastAPI）

## 概要
FastAPI サーバー（診断API）をコンテナまたはローカルで起動するための手順書です。環境変数は `.env` により設定します。

## 前提
- Python 3.11+
- `requirements.txt` に記載の依存関係
- もしくは Docker / Cloud Run 等のコンテナ基盤

## 1. 環境変数の準備

1. サンプルをコピー
   ```bash
   cp server/.env.example server/.env
   ```
2. 必要項目を設定
   - `ENHANCED_DIAGNOSIS_ENABLED`（拡張診断の機能フラグ）
   - `ALLOWED_ORIGINS`（CORS 設定）
   - Vertex AI/Gemini の設定（プロジェクトIDやリージョン）

## 2. ローカル起動（開発）
```bash
cd server
uvicorn src.api.main:app --host 0.0.0.0 --port 8000 --reload
```
- ドキュメント:
  - Swagger UI: http://localhost:8000/docs
  - ReDoc: http://localhost:8000/redoc

## 3. コンテナビルド
```bash
cd server
docker build -t personal-color-api:latest .
```

## 4. コンテナ起動（ローカル）
```bash
docker run --rm -p 8000:8000 --env-file .env personal-color-api:latest
```

## 5. Cloud Run などへのデプロイ（例）
- リージョン、プロジェクト、サービス名を適宜指定
- `.env`相当の環境変数をサービス設定に反映
- 無停止デプロイとロールバック手順を運用手順に沿って実施

## 6. 段階的リリース
- `ENHANCED_DIAGNOSIS_ENABLED=false` で拡張診断を停止
- 指標（429/5xx、応答時間、フォールバック率）を監視しながら `true` へ切替

---

# 付録
- 健全性確認: `/health`, `/health/liveness`, `/metrics`
- OpenAPI スナップショット: `docs/openapi_example.json`

