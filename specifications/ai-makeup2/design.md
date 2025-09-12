# AI画像生成メイク機能改修 - 技術設計書

## 設計概要

パーソナルカラー診断アプリにおいて、現在診断結果画面に配置されている「AI画像生成メイク」機能をトップページに移動し、ユーザビリティを向上させる改修を行う。Clean ArchitectureとDDDパターンを維持しつつ、既存のコンポーネントを活用する設計とする。

## アーキテクチャ設計

### 全体アーキテクチャ

```
┌─────────────────────────────────────────────┐
│              Presentation層                 │
├─────────────────────────────────────────────┤
│ MyHomePage (iOS)  │ AndroidHomePage (Android) │
├─────────────────────────────────────────────┤
│        CameraPage (Platform選択)             │
├─────────────────────────────────────────────┤
│     AIMakeupRecommendationPage (改修)       │
└─────────────────────────────────────────────┘
                    ↕ HTTP API
┌─────────────────────────────────────────────┐
│               Server側                      │
├─────────────────────────────────────────────┤
│         FastAPI (/api/v1/makeup-*）          │
├─────────────────────────────────────────────┤
│  ImagenService (AI画像生成) - 実装必要        │
│  GeminiService (メイク説明生成) - 実装済み    │
└─────────────────────────────────────────────┘
```

### レイヤー責務

#### Presentation層（クライアント）
- **MyHomePage**: iOS向けホーム画面にAI画像生成メイクボタンを追加
- **AndroidHomePage**: Android向けホーム画面にAI画像生成メイクボタンを追加  
- **CameraPage**: 既存カメラページのデフォルト設定を前面カメラに変更
- **AIMakeupRecommendationPage**: AI生成画像のみ表示、リロードボタン削除

#### Service層（サーバー）
- **ImagenService**: Imagen 4.0 APIを使用したAI画像生成（実装必要）
- **GeminiService**: メイク説明文の生成（実装済み）
- **FastAPI エンドポイント**: `/api/v1/makeup-recommendation`（実装済み）

## 詳細設計

### FR-1: トップページへのボタン追加

#### 設計方針
- 既存のデザインシステムとUIコンポーネントを踏襲
- 診断開始ボタンとの視覚的階層を考慮した配置
- プラットフォーム固有のデザインガイドライン準拠

#### 実装設計

##### iOS版 (MyHomePage)

**ファイル**: `client/personal_color_app/lib/main.dart`

**変更内容**:
```dart
// MyHomePage.build() メソッドの修正
Widget build(BuildContext context) {
  // ... 既存コード ...
  
  body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // ... 既存のタイトル・説明文 ...
        
        const SizedBox(height: 40),
        
        // メイン診断ボタン（既存）
        ElevatedButton(
          onPressed: () => _navigateToDiagnosis(context),
          // ... 既存のスタイリング ...
          child: const Text('診断を始める'),
        ),
        
        const SizedBox(height: 16), // 新規追加
        
        // AI画像生成メイクボタン（新規追加）
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToAIMakeup(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI画像生成メイク'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ),
        
        // ... 既存のサブ情報 ...
      ],
    ),
  ),
}

// 新規メソッド追加
void _navigateToAIMakeup(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider(
        create: (context) => di.sl<CameraProvider>()
          ..setDefaultCameraToFront(true), // 前面カメラ指定
        child: const CameraPage(),
      ),
    ),
  );
}
```

##### Android版 (AndroidHomePage)

**ファイル**: `client/personal_color_app/lib/features/home/presentation/android/android_home_page.dart`

**変更内容**:
```dart
// _buildMainCTAButton() の後に新しいセクション追加
Widget build(BuildContext context) {
  // ... 既存コード ...
  
  children: [
    // ... 既存セクション ...
    
    // メインCTAボタン（既存）
    _buildMainCTAButton(context, theme),
    
    const SizedBox(height: 16), // 新規追加
    
    // AI画像生成メイクボタン（新規追加）
    _buildAIMakeupButton(context, theme),
    
    // ... 既存のサブ情報 ...
  ],
}

// 新規メソッド追加
Widget _buildAIMakeupButton(BuildContext context, ThemeData theme) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton.icon(
      onPressed: () => _navigateToAIMakeup(context),
      icon: Icon(
        Icons.auto_awesome,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        'AI画像生成メイク',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: theme.colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

// 新規メソッド追加
void _navigateToAIMakeup(BuildContext context) {
  Navigator.of(context).push(
    _createMaterialPageRoute(
      ChangeNotifierProvider(
        create: (context) => di.sl<CameraProvider>()
          ..setDefaultCameraToFront(true), // 前面カメラ指定
        child: const CameraPage(),
      ),
    ),
  );
}
```

### FR-2: カメラのデフォルト表示変更

#### 設計方針
- 既存のCameraProviderに前面カメラ優先設定を追加
- AI画像生成メイク専用の設定フラグを導入
- 既存の診断機能への影響を回避

#### 実装設計

##### CameraProvider拡張

**ファイル**: `client/personal_color_app/lib/features/camera/presentation/providers/camera_provider.dart`

**変更内容**:
```dart
class CameraProvider extends ChangeNotifier {
  // ... 既存フィールド ...
  
  bool _preferFrontCamera = false; // 新規追加
  
  // 新規getter
  bool get preferFrontCamera => _preferFrontCamera;
  
  // 新規メソッド
  void setDefaultCameraToFront(bool prefer) {
    _preferFrontCamera = prefer;
    notifyListeners();
  }
  
  // 既存のinitializeCamera()メソッドを修正
  Future<void> initializeCamera() async {
    // ... 既存の権限チェック ...
    
    final result = await _initializeCamera.execute(
      InitializeCameraParams(
        preferFrontCamera: _preferFrontCamera, // 新規パラメータ
      ),
    );
    
    // ... 既存のエラーハンドリング ...
  }
}
```

##### データソース層の修正

**ファイル**: `client/personal_color_app/lib/features/camera/data/datasources/camera_data_source.dart`

**変更内容**:
```dart
// selectCamera()メソッドの修正
Future<Either<CameraFailure, CameraController>> selectCamera({
  bool preferFront = false, // 新規パラメータ
}) async {
  try {
    // ... 既存のカメラ取得処理 ...
    
    CameraDescription camera;
    
    if (preferFront) {
      // 前面カメラを優先して選択
      final frontCamera = _cameras!.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      ).firstOrNull;
      
      if (frontCamera != null) {
        camera = frontCamera;
      } else {
        // 前面カメラがない場合は最初のカメラを使用
        camera = _cameras!.first;
      }
    } else {
      // 既存のロジック（背面カメラ優先）
      final backCamera = _cameras!.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      ).firstOrNull;
      
      camera = backCamera ?? _cameras!.first;
    }
    
    // ... 既存のカメラコントローラー初期化 ...
  } catch (e) {
    // ... 既存のエラーハンドリング ...
  }
}
```

### FR-3: AI画像生成画面の表示改修

#### 設計方針
- 既存のAIMakeupRecommendationPageから不要な表示要素を削除
- AI生成画像の表示を中央に配置
- 既存のローディング・エラーハンドリングを維持

#### 実装設計

##### 画面レイアウトの簡素化

**ファイル**: `client/personal_color_app/lib/features/makeup/presentation/pages/ai_makeup_recommendation_page.dart`

**変更内容**:
```dart
// _buildRecommendationScreen()メソッドの修正
Widget _buildRecommendationScreen(AIMakeupRecommendationProvider provider) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _getBackgroundColor(personalColorType),
          _getBackgroundColor(personalColorType).withValues(alpha: 0.1),
        ],
      ),
    ),
    child: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI生成画像のみ表示
          if (provider.generatedImage != null)
            _buildAIGeneratedImage(provider.generatedImage!),
          
          // エラー時の表示
          if (provider.generatedImage == null && !provider.isLoading)
            _buildNoImagePlaceholder(),
        ],
      ),
    ),
  );
}

// 新規メソッド: AI生成画像表示
Widget _buildAIGeneratedImage(String imageUrl) {
  return Container(
    margin: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorPlaceholder();
        },
      ),
    ),
  );
}

// 削除対象メソッド
// - _buildPersonalColorTypeCard() 
// - _buildCategoryHeader()
// - 商品推薦関連の表示メソッド
```

### FR-4: リロードボタンの削除

#### 設計方針
- AppBarのactionsからリロードボタンを削除
- 撮影による自動リロード機能は既存のまま維持

#### 実装設計

**ファイル**: `client/personal_color_app/lib/features/makeup/presentation/pages/ai_makeup_recommendation_page.dart`

**変更内容**:
```dart
// AppBarの修正
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('AI画像生成メイク'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      // actions削除（リロードボタンを削除）
    ),
    body: Consumer<AIMakeupRecommendationProvider>(
      // ... 既存のConsumerロジック ...
    ),
  );
}
```

### 診断結果画面からのボタン削除

#### 実装設計

**ファイル**: `client/personal_color_app/lib/features/diagnosis/presentation/ios/ios_diagnosis_result_page.dart`

**変更内容**:
```dart
// _buildActionButtons()メソッドの修正
Widget _buildActionButtons(BuildContext context) {
  return Column(
    children: [
      // AI画像生成メイクボタン部分を削除（130-218行目）
      // Container(...) ← この部分を削除
      
      // 既存の「おすすめのメイク」ボタンはそのまま維持
      SizedBox(
        width: double.infinity,
        height: 56,
        child: GestureDetector(
          onTap: () => _navigateToMakeupRecommendation(context, forceRefresh: false),
          onLongPress: () {
            debugPrint('🔄 長押し検知: forceRefresh=trueで実行');
            _navigateToMakeupRecommendation(context, forceRefresh: true);
          },
          // ... 既存のメイクボタン実装 ...
        ),
      ),
      
      // ... 既存の他のボタン ...
    ],
  );
}

// _navigateToAIMakeupRecommendation()メソッドは削除
```

## サーバー側設計（追加要件）

### FR-5: AI画像生成機能の実装

#### 設計方針
- 現在のモック実装から実際のImagen 4.0 APIコールに変更
- 既存のImagenServiceクラス構造を維持
- エラーハンドリングとセキュリティ対策を強化

#### 実装設計

##### ImagenService改修

**ファイル**: `server/src/services/imagen_service.py`

**変更内容**:
```python
async def generate_makeup_image(
    self, base_image_bytes: bytes, mime_type: str, personal_color_type: str
) -> Dict[str, Any]:
    """AIメイク画像を生成"""
    try:
        # プロンプトを生成
        prompt = self._create_makeup_prompt(personal_color_type)
        
        # 画像データを準備
        image_data = {
            "mime_type": mime_type,
            "data": base64.b64encode(base_image_bytes).decode("utf-8"),
        }
        
        # Imagen 4.0 で実際の画像生成（モックから変更）
        logger.info(f"Starting AI makeup generation with model: {self._model_name}")
        
        if self._client is None:
            # 開発環境: モック画像を返す
            generated_image_data = await self._generate_mock_response(
                base_image_bytes, personal_color_type
            )
        else:
            # 本番環境: 実際のImagen 4.0 API呼び出し
            generated_image_data = await self._generate_real_makeup_image(
                image_data, prompt
            )
        
        logger.info("AI makeup generation completed successfully")
        
        return {
            "image_data": generated_image_data["image_data"],
            "mime_type": generated_image_data["mime_type"],
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "model_used": self._model_name,
            "personal_color_type": personal_color_type,
        }
        
    except Exception as e:
        # ... 既存のエラーハンドリング ...

async def _generate_real_makeup_image(
    self, image_data: Dict[str, str], prompt: str
) -> Dict[str, str]:
    """実際のImagen 4.0 APIを使用した画像生成（新規実装）"""
    try:
        # Google Gen AI SDK を使用した画像生成
        config = GenerateContentConfig(
            system_instruction="You are a professional makeup artist AI that creates natural, age-appropriate makeup looks.",
            temperature=0.7,
            candidate_count=1,
        )
        
        # 画像とプロンプトで生成リクエスト
        response = await self._client.agenerate_content(
            model=self._model_name,
            contents=[
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": image_data["mime_type"],
                                "data": image_data["data"]
                            }
                        }
                    ]
                }
            ],
            config=config
        )
        
        # 生成された画像データを取得
        if response.candidates and response.candidates[0].content.parts:
            for part in response.candidates[0].content.parts:
                if hasattr(part, 'inline_data') and part.inline_data:
                    return {
                        "image_data": part.inline_data.data,
                        "mime_type": part.inline_data.mime_type or "image/jpeg"
                    }
        
        raise ImageGenerationError("生成された画像データが取得できませんでした")
        
    except Exception as e:
        logger.error(f"Real image generation failed: {e}", exc_info=True)
        raise ImageGenerationError(f"AI画像生成エラー: {str(e)}")
```

##### 環境変数・設定追加

**ファイル**: `server/src/core/config/settings.py`

**追加内容**:
```python
class Settings(BaseSettings):
    # ... 既存設定 ...
    
    # Imagen 4.0 設定
    GOOGLE_CLOUD_PROJECT: str = Field(default="personal-color-469007")
    VERTEX_AI_LOCATION: str = Field(default="asia-northeast1") 
    IMAGEN_MODEL_NAME: str = Field(default="imagen-4.0-generate-001")
    
    # AI画像生成設定
    AI_IMAGE_GENERATION_ENABLED: bool = Field(default=True)
    AI_IMAGE_MAX_RETRIES: int = Field(default=3)
    AI_IMAGE_TIMEOUT_SECONDS: int = Field(default=30)
```

##### API エンドポイント改修

**ファイル**: `server/src/api/endpoints/makeup.py`

**変更内容**:
```python
# get_ai_makeup_recommendation() 関数の画像生成部分を改修
async def get_ai_makeup_recommendation(
    request: Request,
    personal_color_type: str = Form(...),
    image: UploadFile = File(...),
):
    # ... 既存の前処理 ...
    
    # Generate AI makeup image
    generated_image = None
    try:
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, starting AI image generation"
        )
        imagen_service = get_imagen_service()
        
        # 設定確認
        settings = get_settings()
        if not settings.AI_IMAGE_GENERATION_ENABLED:
            logger.warning(
                f"[AI_MAKEUP] request_id={request_id}, AI image generation is disabled"
            )
        else:
            # 実際の画像生成を実行
            image_result = await imagen_service.generate_makeup_image(
                image_bytes, mime_type, validated_type
            )
            
            generated_image = GeneratedImageData(
                image_data=image_result["image_data"],
                mime_type=image_result["mime_type"],
                generated_at=image_result["generated_at"],
                model_used=image_result["model_used"],
            )
            logger.info(
                f"[AI_MAKEUP] request_id={request_id}, AI image generation completed successfully"
            )
    
    except FaceDetectionError as e:
        logger.warning(
            f"[AI_MAKEUP] request_id={request_id}, face detection failed: {e}"
        )
        raise HTTPException(status_code=400, detail=str(e))
    except APILimitError as e:
        logger.warning(
            f"[AI_MAKEUP] request_id={request_id}, API limit reached: {e}"
        )
        raise HTTPException(status_code=429, detail=str(e))
    except ImageGenerationError as e:
        logger.error(
            f"[AI_MAKEUP] request_id={request_id}, image generation failed: {e}"
        )
        # フォールバック: 生成失敗時も他の情報は返す
        logger.info(
            f"[AI_MAKEUP] request_id={request_id}, continuing without generated image due to generation error"
        )
    
    # ... 既存の後処理とレスポンス生成 ...
```

## データフロー設計

### AI画像生成メイク機能の新しいフロー

```
1. トップページ表示
   ↓
2. 「AI画像生成メイク」ボタン押下
   ↓
3. CameraProvider初期化（前面カメラ優先設定）
   ↓
4. カメラ画面表示（前面カメラがデフォルト）
   ↓
5. 撮影実行
   ↓
6. サーバーAPI呼び出し (/api/v1/makeup-recommendation)
   ↓
7. サーバー側AI画像生成（Imagen 4.0）
   ↓
8. AI画像生成・表示画面（簡素化版）
```

### サーバー側データフロー（新規追加）

```
1. FastAPI エンドポイント受信
   ↓
2. 画像データ検証・セキュリティチェック
   ↓
3. ImagenService.generate_makeup_image() 呼び出し
   ↓
4. パーソナルカラー用プロンプト生成
   ↓
5. Imagen 4.0 API呼び出し (Google Gen AI SDK)
   ↓
6. AI生成画像データ取得・検証
   ↓
7. レスポンス生成・返却
```

## 状態管理設計

### CameraProvider状態拡張

```dart
class CameraProvider extends ChangeNotifier {
  // 既存状態
  CameraImage? _capturedImage;
  bool _isInitialized = false;
  String? _errorMessage;
  
  // 新規状態
  bool _preferFrontCamera = false;
  
  // 状態変更メソッド
  void setDefaultCameraToFront(bool prefer) {
    _preferFrontCamera = prefer;
    notifyListeners();
  }
}
```

## エラーハンドリング設計

### 既存エラーハンドリングの維持

- カメラ権限エラー: 既存の権限要求ダイアログを使用
- カメラ初期化エラー: 既存のエラーメッセージを使用
- AI画像生成エラー: 既存のエラー表示を使用

## パフォーマンス設計

### 最適化ポイント

1. **カメラ初期化時間短縮**
   - 前面カメラ優先による初期化処理の効率化
   - 不要なカメラ切り替え処理の削減

2. **メモリ使用量最適化**
   - AI画像生成画面での不要なWidget削減
   - 商品推薦データのロード処理削除

3. **画面遷移最適化**
   - 既存の遷移アニメーションを維持
   - 新規追加ボタンでの遷移処理軽量化

## セキュリティ設計

### セキュリティ要件

- カメラ権限管理: 既存の実装を維持
- 画像データ処理: 既存のセキュリティポリシーに準拠
- AI生成画像: 既存のAPIセキュリティを維持

## テスト設計

### 単体テスト対象

1. **CameraProvider**
   - `setDefaultCameraToFront()` メソッドのテスト
   - 前面カメラ優先初期化のテスト

2. **UI Component**
   - MyHomePage の新規ボタン表示テスト
   - AndroidHomePage の新規ボタン表示テスト

### 統合テスト対象

1. **画面遷移テスト**
   - トップページ → カメラ → AI画像生成の一連フロー
   - 前面カメラがデフォルトで起動することの確認

2. **既存機能影響テスト**
   - 通常の診断フロー（診断開始ボタン経由）
   - 診断結果画面のレイアウト確認

### E2Eテスト対象

1. **ユーザーフロー**
   - トップページからAI画像生成メイクまでの完全フロー
   - エラー発生時のハンドリング確認

## デプロイ設計

### 段階的デプロイ

1. **Phase 1**: カメラ設定変更とProvider拡張
2. **Phase 2**: トップページUIの追加
3. **Phase 3**: AI画像生成画面の簡素化
4. **Phase 4**: 診断結果画面からのボタン削除

### リリース戦略

- フィーチャーフラグによる段階的有効化
- A/Bテストによる既存ユーザーへの影響測定
- ロールバック計画の準備

## 運用・監視設計

### 監視ポイント

1. **パフォーマンス監視**
   - カメラ初期化時間
   - 画面遷移時間
   - AI画像生成完了率

2. **エラー監視**
   - カメラ関連エラー率
   - 新規ボタンの押下エラー率
   - AI画像生成失敗率

3. **利用状況分析**
   - 新規ボタンのクリック率
   - 従来フローとの利用比較
   - ユーザー満足度指標

---

**作成日**: 2025-09-08  
**作成者**: AI Assistant  
**レビュー**: 未実施  
**承認**: 未実施