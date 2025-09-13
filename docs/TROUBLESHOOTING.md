# トラブルシューティングガイド

## 症状別チェックリスト

### 422 validation_error
- 画像の Base64 が不正 / 空になっていないか
- 必須フィールド（image_base64）が存在するか

### 429 Too Many Requests
- 短時間に過剰なアクセスがないか
- レート制限設定（`RATE_LIMIT_*`）を再確認

### 503 ai_service_error
- Gemini/Vertex AI の応答が不安定か（リトライやフォールバック率を確認）
- ネットワーク周辺（APIキー/権限/リージョン設定）

### 500 internal_server_error
- サーバーログに例外スタックトレースがないか（PIIは出力されない）
- 直前のデプロイ/設定変更の影響

## フィーチャーフラグ誤設定
- 拡張診断が404（feature_disabled）を返す → `.env` の `ENHANCED_DIAGNOSIS_ENABLED` を確認

## 画像関連の失敗
- 画像サイズが `MAX_IMAGE_SIZE_MB` を超過していないか
- 形式（JPEG/PNG）や前処理が想定通りか

## ログの見方
- PIIはフィルタ済み（ハッシュ化/マスク）
- 重要: rate limit, fallback, latency, 各種エラーの相関を確認

