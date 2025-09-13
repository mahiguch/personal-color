# CI/CD 構成概要

## テスト戦略（PR / Nightly / Release）

### PR（プルリクエスト）
- Unit Tests（Flutter + Python）
- Integration Tests（主要ケースのみ）
- Lint/Format（black, flake8, mypy / dart analyze, format）

### Nightly（夜間）
- Performance Tests（Flutter 側のパフォーマンス検証）
- E2E Tests（拡張診断フロー/ユーザージャーニー）
- Accuracy/Prompt テスト（将来拡張）

### Release（リリース前）
- Full Test Suite（ユニット/統合/セキュリティ/パフォーマンス）
- Security Scan（依存脆弱性チェック等）
- 本番環境デプロイ → モニタリング確認

## フラグ/環境のマトリクス
- Server: `ENHANCED_DIAGNOSIS_ENABLED=true/false` の両パスをカバー
- Flutter: FeatureFlags をテスト内で override（E2E/Integration）

## アーティファクト
- `docs/openapi_example.json` を成果物として保存（スキーマのドリフト検知）
- テストレポート/カバレッジ（任意）

## 注意点
- 画像/PIIは保存しない（テスト用ダミーデータのみ）
- ログはフィルタ済みであること（個人情報を含まない）

