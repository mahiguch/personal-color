# パーソナルカラー診断 API 仕様（OpenAPI 概要）

本ドキュメントは、FastAPI バックエンドが提供する診断 API のエンドポイント概要と、代表的なリクエスト/レスポンス例を示します。実際のスキーマ詳細は開発モード（DEBUG=true）時の Swagger UI / ReDoc を参照してください。

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 共通事項

- Base URL: `http://localhost:8000/api/v1`
- Content-Type: `application/json`
- 認証: 現状なし（将来的に API キー等を追加予定）

---

## POST /diagnose

画像（Base64）を入力として、標準のパーソナルカラー診断を実行します。人物の年齢・性別情報は含みません。

- Path: `/api/v1/diagnose`
- Method: `POST`
- 説明: Base64エンコード画像をもとに、Spring/Summer/Autumn/Winter のいずれかを診断します。

### Request Body（例）
```json
{
  "image_base64": "/9j/4AAQSkZJRgABAQ...（Base64省略）...",
  "metadata": {
    "timestamp": "2025-01-01T12:00:00Z",
    "app_version": "1.0.0",
    "device_type": "ios"
  }
}
```

- `image_base64`（必須）: 画像の Base64 文字列。`data:image/jpeg;base64,` 等のプレフィックスはあっても可（サーバ側で除去）。
- `metadata`（任意）: 追加情報。PII（個人情報）は送らないでください（ログ上は匿名化処理を実施）。

### 200 OK（成功）レスポンス（例）
```json
{
  "request_id": "diag_1735738297000",
  "timestamp": "2025-01-01T12:00:00.000000",
  "result": {
    "personal_color_type": "Spring",
    "confidence": 78.5,
    "explanation": "明るく温かい色が似合います",
    "recommended_colors": ["#FF6B6B", "#4ECDC4", "#45B7D1"],
    "tips": ["明るい色を選びましょう", "パステルカラーもおすすめです"]
  },
  "processing_time_ms": 850
}
```

### 4xx / 5xx エラー（例）
- 422 Validation Error（Base64不正など）
```json
{
  "error": "validation_error",
  "message": "入力データが不正です",
  "detail": [
    {"type": "value_error", "loc": ["body","image_base64"], "msg": "無効なBase64画像データです"}
  ],
  "request_path": "/api/v1/diagnose"
}
```
- 400 Image Processing Error / 503 AI Service Error / 500 Internal Server Error など

---

## POST /diagnose-enhanced

標準診断に加えて、人物の年代・性別推定を含む拡張診断を実行します。機能フラグ `ENHANCED_DIAGNOSIS_ENABLED` により有効/無効を切り替え可能です。

- Path: `/api/v1/diagnose-enhanced`
- Method: `POST`
- 説明: Base64エンコード画像をもとに、カラータイプ＋`person_analysis`（年代・性別・信頼度）を返します。

### Request Body（例）
```json
{
  "image_base64": "/9j/4AAQSkZJRgABAQ...（Base64省略）...",
  "metadata": {
    "timestamp": "2025-01-01T12:00:00Z",
    "app_version": "1.0.0",
    "device_type": "ios",
    "user_notes": "屋外で撮影"
  }
}
```

### 200 OK（成功）レスポンス（例）
```json
{
  "request_id": "enhanced_diag_1735738297000",
  "timestamp": "2025-01-01T12:00:00.000000",
  "result": {
    "personal_color_type": "Spring",
    "confidence": 85.0,
    "explanation": "あなたは明るく華やかな春タイプです！",
    "recommended_colors": ["コーラルピンク", "イエローグリーン", "アクアブルー"],
    "tips": [
      "明るい色を選んで元気な印象を演出しましょう",
      "ゴールド系のアクセサリーがおすすめです",
      "ビジネスや日常シーンで実用的に取り入れましょう"
    ],
    "person_analysis": {
      "age_group": "adult",
      "gender": "female",
      "confidence": 78
    }
  },
  "processing_time_ms": 900
}
```

- `person_analysis.age_group`: `child | student | adult | middleAge | senior`
- `person_analysis.gender`: `male | female | unknown`

### 機能フラグ OFF 時（例）
- `ENHANCED_DIAGNOSIS_ENABLED=false` の場合、エンドポイントは 404 を返します。
```json
{
  "detail": {
    "error": "feature_disabled",
    "message": "Enhanced diagnosis is currently disabled"
  }
}
```

### 4xx / 5xx エラー（例）
- 422 Validation Error（Base64不正など）
- 400 Image Processing Error / 503 AI Service Error / 500 Internal Server Error など

---

## OpenAPI（スキーマ）

開発モードでは以下でスキーマを確認できます：

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

代表的なレスポンスモデル：

- `DiagnosisResponse`
  - `request_id: string`
  - `timestamp: string` (ISO8601)
  - `result: PersonalColorResult`
  - `processing_time_ms: integer`
- `EnhancedDiagnosisResponse`
  - `request_id: string`
  - `timestamp: string` (ISO8601)
  - `result: EnhancedPersonalColorResult`
  - `processing_time_ms: integer`
- `PersonalColorResult`
  - `personal_color_type: string` (`Spring|Summer|Autumn|Winter`)
  - `confidence: number`
  - `explanation: string`
  - `recommended_colors: string[]`
  - `tips: string[]`
- `EnhancedPersonalColorResult`
  - 上記に加えて `person_analysis`
- `PersonAnalysis`
  - `age_group: string` (`child|student|adult|middleAge|senior`)
  - `gender: string` (`male|female|unknown`)
  - `confidence: number (0-100)`

---

## cURL 例

標準診断：
```bash
curl -X POST \
  http://localhost:8000/api/v1/diagnose \
  -H 'Content-Type: application/json' \
  -d '{
    "image_base64": "<BASE64>",
    "metadata": {"app_version":"1.0.0","device_type":"ios"}
  }'
```

拡張診断：
```bash
curl -X POST \
  http://localhost:8000/api/v1/diagnose-enhanced \
  -H 'Content-Type: application/json' \
  -d '{
    "image_base64": "<BASE64>",
    "metadata": {"app_version":"1.0.0","device_type":"ios"}
  }'
```

---

## プライバシー配慮

- 画像データは検証・処理後にメモリからクリーンアップされます。
- レスポンスには画像や個人特定情報を含めません。
- ログはプライバシーフィルタを通過し、個人情報はハッシュ等で匿名化されます。

