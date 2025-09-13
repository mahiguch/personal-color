# エラーコード一覧（日本語/英語対訳）

APIレスポンスの`detail`またはトップレベルに含まれる典型的なエラーコードと、その意味・ユーザー向け/開発者向けメッセージの対照表です。

| コード | HTTP | 日本語（ユーザー向け） | 英語（開発者向け） | 典型的な原因/対処 |
|---|---|---|---|---|
| `validation_error` | 422 | 入力データが不正です。 | Input data is invalid. | Base64文字列が不正、必須フィールド欠落。入力を見直す。 |
| `image_processing_error` | 400 | 画像処理中にエラーが発生しました。 | Error during image processing. | 画像サイズ/形式が想定外。別の画像で再試行。 |
| `ai_service_error` | 503 | AI診断サービスでエラーが発生しました。 | AI service error. | 外部AI応答の一時的障害。時間を置いて再試行。 |
| `internal_server_error` | 500 | サーバー内部エラーが発生しました。 | Internal server error. | 想定外の例外。ログを確認し、再現手順を特定。 |
| `feature_disabled` | 404 | 機能が無効化されています。 | Feature is disabled. | `ENHANCED_DIAGNOSIS_ENABLED=false` で拡張診断OFF。必要に応じてONに。 |

補足:
- すべてのエラーはPIIを含まない形で返却されます。
- 詳細な検証エラーは `validation_error.detail[]` に配列で含まれます（FastAPI/Pydantic準拠）。
- 運用時は429（レート制限）も監視対象です。レート制限値は環境変数で調整できます。

