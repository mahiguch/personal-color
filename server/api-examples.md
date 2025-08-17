# Personal Color API - 使用例

Production API URL: `https://personal-color-api-666814602151.asia-northeast1.run.app`

## 基本的なAPIテスト

### 1. ヘルスチェック

```bash
curl -X GET "https://personal-color-api-666814602151.asia-northeast1.run.app/api/v1/diagnose/test"
```

**期待するレスポンス:**
```json
{
  "status": "ok",
  "gemini_service": "healthy",
  "timestamp": "2025-08-17T01:00:00.000000",
  "message": "診断エンドポイントは正常に動作しています"
}
```

### 2. プライバシーポリシー取得

```bash
curl -X GET "https://personal-color-api-666814602151.asia-northeast1.run.app/api/v1/privacy/policy"
```

### 3. パーソナルカラー診断（Base64画像）

```bash
curl -X POST "https://personal-color-api-666814602151.asia-northeast1.run.app/api/v1/diagnose" \
  -H "Content-Type: application/json" \
  -d '{
    "image_base64": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/...",
    "metadata": {
      "app_version": "1.0.0",
      "device_type": "iPhone",
      "platform": "ios"
    }
  }'
```

**期待するレスポンス:**
```json
{
  "request_id": "diag_1755405413338",
  "timestamp": "2025-08-17T04:36:53.338183",
  "result": {
    "personal_color_type": "Autumn",
    "confidence": 85.0,
    "explanation": "あなたのお肌は、なんだかあったかい感じの黄色っぽい色をしているね！髪の毛は落ち着いた黒色で、瞳もくっきりとした濃い茶色だから、まるで秋の森みたいに、深みのある色がとっても似合うんだよ。",
    "recommended_colors": [
      "カーキ",
      "マスタードイエロー", 
      "テラコッタ（レンガ色）",
      "ブラウン",
      "オリーブグリーン"
    ],
    "tips": [
      "落ち着いた色の服を着ると、あなたの頼りになる素敵な魅力がもっと輝くよ！",
      "アクセサリーは、キラキラしたゴールド系が特におすすめだよ。",
      "もしおしゃれをするなら、深みのある緑や茶色、オレンジっぽい色がとっても似合うよ。"
    ]
  },
  "processing_time_ms": 23680
}
```

### 4. ファイルアップロード診断

```bash
curl -X POST "https://personal-color-api-666814602151.asia-northeast1.run.app/api/v1/diagnose/upload" \
  -F "file=@/path/to/your/image.jpg" \
  -F 'metadata={"app_version":"1.0.0","device_type":"iPhone","platform":"ios"}'
```

## Flutter統合用のサンプルコード

### Dart/Flutter HTTPリクエスト例

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class PersonalColorAPI {
  static const String baseUrl = 'https://personal-color-api-666814602151.asia-northeast1.run.app';
  
  // ヘルスチェック
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/diagnose/test'),
    );
    return json.decode(response.body);
  }
  
  // パーソナルカラー診断
  static Future<Map<String, dynamic>> diagnosePersonalColor({
    required String imageBase64,
    required Map<String, dynamic> metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/diagnose'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'image_base64': imageBase64,
        'metadata': metadata,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('診断に失敗しました: ${response.statusCode}');
    }
  }
  
  // ファイルアップロード診断
  static Future<Map<String, dynamic>> diagnoseFromFile({
    required String filePath,
    required Map<String, dynamic> metadata,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/diagnose/upload'),
    );
    
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['metadata'] = json.encode(metadata);
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return json.decode(responseBody);
    } else {
      throw Exception('アップロード診断に失敗しました: ${response.statusCode}');
    }
  }
}
```

## レート制限について

- **一般的なエンドポイント**: 60リクエスト/分
- **診断エンドポイント**: 10リクエスト/分
- **バースト制限**: 5リクエスト/短時間

## エラーハンドリング

### 一般的なエラーレスポンス形式

```json
{
  "detail": {
    "error": "validation_error",
    "message": "画像データが無効です",
    "detail": "Base64 decoding failed"
  }
}
```

### HTTPステータスコード

- `200`: 成功
- `400`: 不正なリクエスト
- `422`: バリデーションエラー
- `429`: レート制限
- `500`: サーバーエラー
- `503`: サービス利用不可

## 画像要件

- **サポート形式**: JPEG, PNG
- **最大ファイルサイズ**: 10MB
- **推奨解像度**: 1024x1024以下
- **Base64エンコード**: Data URL形式 (`data:image/jpeg;base64,...`)

## セキュリティ

- **HTTPS必須**: すべてのリクエストはHTTPS経由
- **CORS**: 設定済み（すべてのオリジンを許可）
- **レート制限**: IP別の制限実装済み