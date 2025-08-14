# 詳細設計書 - パーソナルカラー診断アプリ

## 1. アーキテクチャ概要

### 1.1 システム構成図

```
┌─────────────────┐    HTTPS    ┌─────────────────┐    API Call   ┌─────────────────┐
│   Flutter iOS   │ ─────────→  │  ADK Server     │ ──────────→  │  Vertex AI      │
│   Application   │             │  (Agent Engine) │             │  (Gemini-2.5)   │
└─────────────────┘             └─────────────────┘             └─────────────────┘
        │                               │
        │                               │
        ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│   iPhone        │             │   GCP Project   │
│   - Camera      │             │   - Cloud       │
│   - UI/UX       │             │   - Security    │
└─────────────────┘             └─────────────────┘
```

### 1.2 技術スタック

- **クライアント言語**: Dart 3.0+
- **クライアントフレームワーク**: Flutter 3.13+
- **対象プラットフォーム**: iOS (iPhone)
- **サーバー言語**: Python 3.11+
- **サーバーSDK**: ADK (Agent Development Kit) Python SDK
- **サーバー実行環境**: Agent Engine
- **AI**: Vertex AI Gemini-2.5-pro
- **クラウドプラットフォーム**: Google Cloud Platform
- **通信プロトコル**: HTTPS/REST API
- **画像形式**: JPEG (Base64エンコード)
- **データ形式**: JSON

## 2. コンポーネント設計

### 2.1 コンポーネント一覧

| コンポーネント名 | 責務 | 依存関係 |
|---|---|---|
| **CameraView** | カメラ撮影UI制御 | camera, permission_handler |
| **ImageProcessor** | 画像変換・圧縮 | image |
| **ApiClient** | サーバー通信管理 | http, dio |
| **DiagnosisService** | 診断ロジック統合 | ApiClient |
| **ResultView** | 診断結果表示 | - |
| **ErrorHandler** | エラー処理統合 | - |
| **ADKServer** | サーバーエンドポイント | Agent Engine |
| **GeminiService** | AI画像解析 | Vertex AI |

### 2.2 各コンポーネントの詳細

#### CameraView (Flutter)
- **目的**: 前面カメラでの自撮り撮影機能
- **公開インターフェース**:
  ```dart
  class CameraView extends StatefulWidget {
    Future<File?> takePicture();
    void requestCameraPermission();
  }
  ```
- **内部実装方針**: 
  - camera pluginを使用
  - カメラ権限の適切な処理
  - 撮影後の画像ファイル返却

#### ImageProcessor (Flutter)
- **目的**: 撮影画像の圧縮とBase64変換
- **公開インターフェース**:
  ```dart
  class ImageProcessor {
    static Future<String> convertToBase64(File imageFile);
    static Future<File> compressImage(File originalFile);
  }
  ```
- **内部実装方針**:
  - 画像サイズを適切に圧縮（1MB以下目標）
  - JPEG品質調整（85%程度）
  - Base64エンコード処理

#### ApiClient (Flutter)
- **目的**: サーバーAPIとの通信管理
- **公開インターフェース**:
  ```dart
  class ApiClient {
    Future<DiagnosisResponse> diagnosePicture(String base64Image);
    void configureHttpClient();
  }
  ```
- **内部実装方針**:
  - HTTPS通信の暗号化
  - タイムアウト設定（30秒）
  - リトライ機能（最大3回）

#### DiagnosisService (Flutter)
- **目的**: 診断フローの統合管理
- **公開インターフェース**:
  ```dart
  class DiagnosisService {
    Future<DiagnosisResult> diagnoseFromImage(File imageFile);
  }
  ```
- **内部実装方針**:
  - ImageProcessor → ApiClient の連携
  - エラーハンドリングの統合
  - ローディング状態管理

#### ADKServer (サーバー)
- **目的**: クライアントからのリクエスト受信と処理
- **公開インターフェース**:
  ```python
  # ADK Python SDK
  @app.post("/api/diagnose")
  async def diagnose_picture(request: DiagnoseRequest) -> DiagnoseResponse:
      pass
  ```
- **内部実装方針**:
  - ADK Python SDKでの実行
  - GeminiServiceへの委譲
  - レスポンス形式の統一

#### GeminiService (サーバー)
- **目的**: Vertex AI Gemini-2.5-proでの画像解析
- **公開インターフェース**:
  ```python
  class GeminiService:
      async def analyze_personal_color(self, base64_image: str) -> AnalysisResult:
          pass
  ```
- **内部実装方針**:
  - 最適化されたプロンプト設計
  - Vertex AI APIとの連携
  - レスポンス解析とデータ変換

## 3. データフロー

### 3.1 データフロー図

```
[User] → [Camera] → [Image File] → [ImageProcessor] → [Base64]
                                                        ↓
[ResultView] ← [DiagnosisResult] ← [DiagnosisService] ← [ApiClient]
                                                        ↓
[ErrorHandler] ← [Error Response] ← [ADKServer] → [GeminiService] → [Vertex AI]
```

### 3.2 データ変換

#### 入力データ形式
```dart
// カメラから取得
File imageFile;  // JPEG形式
```

#### 中間データ形式
```dart
// Base64変換後
String base64Image = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...";
```

#### APIリクエスト形式
```json
{
  "image": "/9j/4AAQSkZJRgABAQEAYABgAAD...",
  "timestamp": "2025-08-14T10:30:00Z"
}
```

#### 出力データ形式
```json
{
  "result": "イエベ",
  "reason": "肌に暖かみのある黄色味が感じられ、ゴールドトーンが似合う特徴があります。",
  "confidence": 0.85,
  "timestamp": "2025-08-14T10:30:05Z"
}
```

## 4. APIインターフェース

### 4.1 診断API

#### エンドポイント
```
POST /api/diagnose
```

#### リクエストヘッダー
```
Content-Type: application/json
Accept: application/json
```

#### リクエストボディ
```json
{
  "image": "string",        // Base64エンコードされたJPEG画像
  "timestamp": "string"     // ISO 8601形式のタイムスタンプ
}
```

#### 成功レスポンス (200 OK)
```json
{
  "success": true,
  "data": {
    "result": "イエベ" | "ブルベ",
    "reason": "string",
    "confidence": "number",
    "timestamp": "string"
  }
}
```

#### エラーレスポンス
```json
{
  "success": false,
  "error": {
    "code": "string",
    "message": "string",
    "timestamp": "string"
  }
}
```

### 4.2 ヘルスチェックAPI

#### エンドポイント
```
GET /api/health
```

#### レスポンス (200 OK)
```json
{
  "status": "healthy",
  "timestamp": "string",
  "version": "string"
}
```

## 5. エラーハンドリング

### 5.1 エラー分類

#### クライアントサイドエラー
- **CAMERA_PERMISSION_DENIED**: カメラアクセス拒否
  - 対処: 設定画面への誘導メッセージ表示
- **CAMERA_NOT_AVAILABLE**: カメラ利用不可
  - 対処: 「カメラが利用できません」エラー表示
- **IMAGE_PROCESSING_FAILED**: 画像処理失敗
  - 対処: 「写真の処理に失敗しました。もう一度撮影してください」
- **NETWORK_ERROR**: ネットワーク接続エラー
  - 対処: 「インターネット接続を確認してください」

#### サーバーサイドエラー
- **INVALID_IMAGE**: 不正な画像データ
  - HTTPステータス: 400
  - 対処: 「画像形式が正しくありません」
- **AI_SERVICE_ERROR**: AI解析エラー
  - HTTPステータス: 503
  - 対処: 「診断サービスが一時的に利用できません」
- **RATE_LIMIT_EXCEEDED**: レート制限
  - HTTPステータス: 429
  - 対処: 「しばらく時間をおいてから再度お試しください」

### 5.2 エラー通知

#### クライアント側
```dart
class ErrorHandler {
  static void showError(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
        content: Text(error.userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

#### サーバー側ログ
```python
import logging

logger = logging.getLogger(__name__)

logger.error('Diagnosis failed', extra={
    'error': str(error),
    'request_id': request.id,
    'timestamp': datetime.now().isoformat(),
    'user_agent': request.headers.get('user-agent')
})
```

## 6. セキュリティ設計

### 6.1 データ保護

#### 画像データの取り扱い
- **クライアント**: 診断完了後に画像ファイルを即座に削除
- **サーバー**: 受信した画像データはメモリ上でのみ処理、永続化しない
- **AI処理**: Vertex AIでの一時的な処理のみ、保存しない

#### 通信の暗号化
- HTTPS/TLS 1.3以上での通信
- 証明書の適切な検証
- HSTS (HTTP Strict Transport Security) の有効化

### 6.2 プライバシー保護

#### iOS Privacy Manifest
```xml
<key>NSCameraUsageDescription</key>
<string>パーソナルカラー診断のため、顔写真を撮影します</string>
```

#### データ収集ポリシー
- 個人を特定できる情報は収集しない
- 画像データは診断処理のみに使用
- 診断履歴は端末に保存しない

## 7. テスト設計

**詳細なテスト設計については、`specifications/test_design.md`で定義します。**

### 7.1 主要テスト観点

#### 機能テスト
- カメラ撮影フロー
- 画像処理・変換
- API通信
- 診断結果表示
- エラーハンドリング

#### 非機能テスト
- パフォーマンス（10秒以内の診断）
- セキュリティ（画像データ保護）
- 可用性（ネットワーク障害対応）

## 8. パフォーマンス最適化

### 8.1 想定される負荷

#### クライアント側
- 画像処理: 2-3秒以内
- API通信: 5-7秒以内
- 総合応答時間: 10秒以内

#### サーバー側
- 同時リクエスト: 10-50件/分程度
- Vertex AI レスポンス: 3-5秒
- メモリ使用量: 画像データの一時保持のみ

### 8.2 最適化方針

#### 画像処理最適化
- 適切な圧縮率設定（品質85%、1MB以下）
- 非同期処理での応答性向上
- プログレスインジケーター表示

#### サーバー側最適化
- Agent Engineでの効率的なリソース管理
- Vertex AI APIの適切なタイムアウト設定
- エラー時の適切なレスポンス

## 9. デプロイメント

### 9.1 デプロイ構成

#### クライアント
- App Store Connect経由での配布
- iOS 14.0以上をターゲット
- iPhone専用（iPad対応なし）

#### サーバー
- ADK Python SDK環境でのAgent Engine実行
- GCP上での稼働
- 環境変数での設定管理

### 9.2 設定管理

#### 環境変数
```bash
# サーバー設定
VERTEX_AI_PROJECT_ID=your-gcp-project
VERTEX_AI_LOCATION=asia-northeast1
API_PORT=8080

# セキュリティ設定
CORS_ORIGIN=https://your-client-domain
RATE_LIMIT_WINDOW=60
RATE_LIMIT_MAX=100

# Python環境
PYTHONPATH=/app
```

## 10. Geminiプロンプト設計

### 10.1 基本プロンプト

```text
あなたはパーソナルカラー診断の専門家です。
提供された顔写真を分析して、イエローベース（イエベ）かブルーベース（ブルベ）かを判定してください。

判定基準：
- 肌の色味（黄味/赤味）
- 肌の質感
- 顔全体の色調バランス

回答形式：
- result: "イエベ" または "ブルベ"
- reason: 判定理由を小学5年生にも分かりやすい言葉で説明（50文字程度）
- confidence: 判定の信頼度（0.0-1.0）

注意：
- エンターテイメント目的の診断です
- ユーザーが楽しめる前向きな表現を心がけてください
- 医学的な判断ではないことを前提としてください
```

### 10.2 レスポンス解析

Geminiからのレスポンステキストを以下の形式でパース：

```python
from typing import TypedDict

class GeminiResponse(TypedDict):
    result: str  # 'イエベ' または 'ブルベ'
    reason: str
    confidence: float
```

## 11. 実装上の注意事項

### 11.1 Flutter実装
- **状態管理**: Provider または Riverpod を使用
- **依存性注入**: get_it パッケージの活用
- **ルーティング**: go_router での画面遷移
- **非同期処理**: async/await の適切な使用

### 11.2 ADK Python SDK実装
- **Web Framework**: FastAPI または Flask の使用
- **非同期処理**: asyncio での適切な非同期実行
- **エラーハンドリング**: try-except での適切な例外処理
- **ログ**: Python logging での構造化ログ出力
- **設定**: 環境変数での柔軟な設定管理
- **依存関係**: requirements.txt での明確な管理

### 11.3 品質管理
- **コードレビュー**: Pull Request による品質チェック
- **テスト**: 単体・統合テストの自動実行
- **静的解析**: Dart/Flutter の lint ルール適用
- **パフォーマンス**: 定期的なパフォーマンス測定

### 11.4 リリース準備
- **App Store準備**: メタデータ、スクリーンショット作成
- **プライバシーポリシー**: データ利用に関する明記
- **利用規約**: エンターテイメント用途の明記
- **サポート**: 問い合わせ先の準備

---

**次のステップ**: この設計に基づいて`specifications/test_design.md`でテスト設計を行い、その後`specifications/tasks.md`でタスク分解を実施します。
