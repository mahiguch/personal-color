# AI ファッションコーディネート生成機能 - 技術設計書

## 1. アーキテクチャ概要

### 1.1 システム構成

```mermaid
graph TB
    subgraph "Client (Flutter)"
        A[ファッション画面] --> B[カメラ撮影]
        A --> C[AI生成表示]
        C --> D[画像表示]
        C --> E[推薦理由表示]
        C --> F[コーデポイント表示]
    end
    
    subgraph "Server API"
        G[/api/v1/ai-coordinate] --> H[画像処理サービス]
        H --> I[Imagen生成サービス]
        H --> J[Gemini解析サービス]
        I --> K[生成画像返却]
        J --> L[テキスト生成返却]
    end
    
    subgraph "External APIs"
        M[Imagen-4.0 API]
        N[Gemini API]
        O[パーソナルカラーDB]
    end
    
    B --> G
    I --> M
    J --> N
    H --> O
```

### 1.2 技術スタック

#### 1.2.1 フロントエンド (Flutter)
- **Flutter Framework**: 既存のUI基盤を活用
- **状態管理**: Provider/Riverpod（既存実装に合わせる）
- **画像処理**: image_picker, image パッケージ
- **HTTP通信**: dio パッケージ
- **キャッシュ**: flutter_cache_manager

#### 1.2.2 バックエンド (Python)
- **フレームワーク**: FastAPI（既存API基盤）
- **AI SDK**: google-genai パッケージ
- **画像処理**: Pillow, opencv-python
- **非同期処理**: asyncio, aiohttp
- **検証**: pydantic

#### 1.2.3 外部サービス
- **Imagen-4.0**: ファッション画像生成
- **Gemini Pro**: 推薦理由・ポイント生成
- **既存DB**: パーソナルカラー診断結果

## 2. API設計

### 2.1 新規エンドポイント

#### 2.1.1 AI ファッションコーディネート生成
```http
POST /api/v1/ai-coordinate
Content-Type: multipart/form-data

# Request Body
{
  "image": "<image_file>",
  "personal_color_type": "spring|summer|autumn|winter",
  "style_preference": "casual|formal|sporty", // オプション
  "season": "spring|summer|autumn|winter" // オプション
}

# Response
{
  "success": true,
  "data": {
    "generated_image": {
      "base64": "<base64_encoded_image>",
      "format": "jpeg",
      "width": 1024,
      "height": 1024
    },
    "recommendation": {
      "reason": "あなたのスプリングタイプには...",
      "styling_points": [
        "明るいパステルカラーでフレッシュな印象に",
        "軽やかな素材感で春らしさを演出",
        "アクセサリーでポイントを加えて"
      ],
      "color_analysis": {
        "main_colors": ["#FFB6C1", "#98FB98"],
        "color_harmony": "analogous"
      }
    },
    "metadata": {
      "estimated_age": 25,
      "detected_season": "spring",
      "generation_time": 45.2,
      "model_version": "imagen-4.0"
    }
  }
}

# Error Response
{
  "success": false,
  "error": {
    "code": "FACE_NOT_DETECTED",
    "message": "顔が検出できませんでした。別の写真をお試しください。"
  }
}
```

### 2.2 エラーコード定義

```python
class ErrorCodes:
    FACE_NOT_DETECTED = "FACE_NOT_DETECTED"
    IMAGE_TOO_LARGE = "IMAGE_TOO_LARGE"
    INVALID_IMAGE_FORMAT = "INVALID_IMAGE_FORMAT"
    AI_SERVICE_UNAVAILABLE = "AI_SERVICE_UNAVAILABLE"
    GENERATION_TIMEOUT = "GENERATION_TIMEOUT"
    INAPPROPRIATE_CONTENT = "INAPPROPRIATE_CONTENT"
    QUOTA_EXCEEDED = "QUOTA_EXCEEDED"
    INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR"
```

## 3. ドメイン設計 (DDD)

### 3.1 ドメインモデル

#### 3.1.1 エンティティ

```python
from dataclasses import dataclass
from typing import List, Optional
from enum import Enum

class PersonalColorType(Enum):
    SPRING = "spring"
    SUMMER = "summer"
    AUTUMN = "autumn"
    WINTER = "winter"

class StylePreference(Enum):
    CASUAL = "casual"
    FORMAL = "formal"
    SPORTY = "sporty"

@dataclass
class UserPhoto:
    """ユーザー撮影写真のドメインエンティティ"""
    image_data: bytes
    format: str
    width: int
    height: int
    estimated_age: Optional[int] = None
    
    def is_valid_format(self) -> bool:
        return self.format.lower() in ['jpeg', 'jpg', 'png']
    
    def is_appropriate_size(self) -> bool:
        return self.width >= 256 and self.height >= 256

@dataclass
class FashionCoordinate:
    """ファッションコーディネートのドメインエンティティ"""
    generated_image: bytes
    recommendation_reason: str
    styling_points: List[str]
    main_colors: List[str]
    estimated_age: int
    style_type: StylePreference
    
    def is_age_appropriate(self) -> bool:
        # 年齢に適したスタイルかチェック
        return True  # 実装時に詳細ロジック

@dataclass
class CoordinateRequest:
    """コーディネート生成リクエストのドメインエンティティ"""
    user_photo: UserPhoto
    personal_color_type: PersonalColorType
    style_preference: Optional[StylePreference] = None
    season: Optional[str] = None
```

#### 3.1.2 バリューオブジェクト

```python
@dataclass(frozen=True)
class ColorPalette:
    """パーソナルカラーパレットのバリューオブジェクト"""
    primary_colors: List[str]
    accent_colors: List[str]
    neutral_colors: List[str]
    
    def get_seasonal_colors(self, season: str) -> List[str]:
        # 季節に応じた色の組み合わせを返す
        pass

@dataclass(frozen=True)
class GenerationMetadata:
    """生成メタデータのバリューオブジェクト"""
    generation_time: float
    model_version: str
    confidence_score: float
    safety_score: float
```

### 3.2 ドメインサービス

#### 3.2.1 年齢推定サービス

```python
class AgeEstimationService:
    """画像から年齢を推定するドメインサービス"""
    
    async def estimate_age(self, photo: UserPhoto) -> int:
        """
        画像から年齢を推定
        Returns: 推定年齢 (18-80の範囲)
        """
        # Gemini Vision APIを使用した年齢推定
        pass
    
    def get_age_appropriate_style(self, age: int) -> StylePreference:
        """年齢に適したスタイルを推薦"""
        if age < 20:
            return StylePreference.CASUAL
        elif age < 40:
            return StylePreference.CASUAL  # またはFORMAL
        else:
            return StylePreference.FORMAL
```

#### 3.2.2 パーソナルカラー適用サービス

```python
class PersonalColorService:
    """パーソナルカラーに基づくファッション提案サービス"""
    
    def get_color_palette(self, color_type: PersonalColorType) -> ColorPalette:
        """パーソナルカラータイプから色パレットを取得"""
        palettes = {
            PersonalColorType.SPRING: ColorPalette(
                primary_colors=["#FFB6C1", "#98FB98", "#F0E68C"],
                accent_colors=["#FF69B4", "#32CD32"],
                neutral_colors=["#F5F5DC", "#FFFACD"]
            ),
            # 他のタイプも定義
        }
        return palettes[color_type]
    
    def generate_style_recommendation(
        self, 
        color_type: PersonalColorType, 
        age: int,
        season: str
    ) -> str:
        """パーソナルカラーと年齢に基づく推薦理由を生成"""
        pass
```

### 3.3 アプリケーションサービス

#### 3.3.1 AI ファッションコーディネートサービス

```python
class AIFashionCoordinateService:
    """おすすめコーデ生成のアプリケーションサービス"""
    
    def __init__(
        self,
        imagen_service: ImagenGenerationService,
        gemini_service: GeminiAnalysisService,
        age_estimation_service: AgeEstimationService,
        personal_color_service: PersonalColorService
    ):
        self.imagen_service = imagen_service
        self.gemini_service = gemini_service
        self.age_estimation_service = age_estimation_service
        self.personal_color_service = personal_color_service
    
    async def generate_coordinate(
        self, 
        request: CoordinateRequest
    ) -> FashionCoordinate:
        """ファッションコーディネートを生成"""
        
        # 1. 年齢推定
        estimated_age = await self.age_estimation_service.estimate_age(
            request.user_photo
        )
        
        # 2. 年齢適切なスタイル決定
        age_appropriate_style = self.age_estimation_service.get_age_appropriate_style(
            estimated_age
        )
        
        # 3. パーソナルカラーパレット取得
        color_palette = self.personal_color_service.get_color_palette(
            request.personal_color_type
        )
        
        # 4. ファッション画像生成
        generated_image = await self.imagen_service.generate_fashion_image(
            user_photo=request.user_photo,
            color_palette=color_palette,
            style=age_appropriate_style,
            age=estimated_age
        )
        
        # 5. 推薦理由・ポイント生成
        recommendation = await self.gemini_service.generate_recommendation(
            personal_color_type=request.personal_color_type,
            style=age_appropriate_style,
            age=estimated_age,
            season=request.season
        )
        
        return FashionCoordinate(
            generated_image=generated_image,
            recommendation_reason=recommendation.reason,
            styling_points=recommendation.styling_points,
            main_colors=color_palette.primary_colors,
            estimated_age=estimated_age,
            style_type=age_appropriate_style
        )
```

## 4. インフラストラクチャ設計

### 4.1 外部API統合

#### 4.1.1 Imagen サービス実装

```python
class ImagenGenerationService:
    """Imagen-4.0を使用した画像生成サービス"""
    
    def __init__(self, api_key: str):
        self.client = genai.Client(api_key=api_key)
        self.model = "imagen-4.0-generate-001"
    
    async def generate_fashion_image(
        self,
        user_photo: UserPhoto,
        color_palette: ColorPalette,
        style: StylePreference,
        age: int
    ) -> bytes:
        """ファッション着用画像を生成"""
        
        prompt = self._build_fashion_prompt(
            color_palette, style, age
        )
        
        try:
            response = await self.client.models.generate_image(
                model=self.model,
                prompt=prompt,
                image=user_photo.image_data,
                aspect_ratio="1:1",
                safety_filter_level="block_most",
                style="photographic"
            )
            
            return response.image_data
            
        except Exception as e:
            raise AIServiceException(f"Imagen generation failed: {e}")
    
    def _build_fashion_prompt(
        self,
        color_palette: ColorPalette,
        style: StylePreference,
        age: int
    ) -> str:
        """ファッション生成用プロンプトを構築"""
        
        age_descriptors = {
            (0, 18): "teen, youthful",
            (18, 30): "young adult, trendy",
            (30, 50): "mature, sophisticated",
            (50, 100): "elegant, refined"
        }
        
        age_desc = next(
            desc for (min_age, max_age), desc in age_descriptors.items()
            if min_age <= age < max_age
        )
        
        style_descriptions = {
            StylePreference.CASUAL: "casual, comfortable, relaxed",
            StylePreference.FORMAL: "formal, professional, elegant",
            StylePreference.SPORTY: "sporty, athletic, active"
        }
        
        colors_str = ", ".join(color_palette.primary_colors)
        
        return f"""
        Fashion photography of a {age_desc} person wearing {style_descriptions[style]} 
        clothing in colors {colors_str}. The outfit should be age-appropriate, 
        well-coordinated, and suitable for someone with these personal colors.
        High quality, professional fashion photography style.
        """
```

#### 4.1.2 Gemini サービス実装

```python
class GeminiAnalysisService:
    """Gemini APIを使用した分析・テキスト生成サービス"""
    
    def __init__(self, api_key: str):
        self.client = genai.Client(api_key=api_key)
        self.model = "gemini-1.5-pro"
    
    async def generate_recommendation(
        self,
        personal_color_type: PersonalColorType,
        style: StylePreference,
        age: int,
        season: Optional[str] = None
    ) -> RecommendationText:
        """推薦理由とスタイリングポイントを生成"""
        
        prompt = self._build_recommendation_prompt(
            personal_color_type, style, age, season
        )
        
        try:
            response = await self.client.models.generate_content(
                model=self.model,
                prompt=prompt,
                generation_config={
                    "temperature": 0.7,
                    "max_output_tokens": 500,
                    "response_mime_type": "application/json"
                }
            )
            
            result = json.loads(response.text)
            return RecommendationText(
                reason=result["reason"],
                styling_points=result["styling_points"]
            )
            
        except Exception as e:
            raise AIServiceException(f"Gemini analysis failed: {e}")
    
    def _build_recommendation_prompt(
        self,
        personal_color_type: PersonalColorType,
        style: StylePreference,
        age: int,
        season: Optional[str]
    ) -> str:
        """推薦テキスト生成用プロンプト"""
        
        season_context = f"現在は{season}です。" if season else ""
        
        return f"""
        {age}歳の{personal_color_type.value}タイプの方に、{style.value}スタイルの
        ファッションを推薦する理由とスタイリングポイントを生成してください。
        {season_context}
        
        以下のJSON形式で回答してください：
        {{
            "reason": "パーソナルカラーとの関連性を含む推薦理由（100文字程度）",
            "styling_points": [
                "具体的なスタイリングポイント1",
                "具体的なスタイリングポイント2",
                "具体的なスタイリングポイント3"
            ]
        }}
        
        ・年齢に適した表現を使用
        ・パーソナルカラーの特徴を活かした説明
        ・実践的で分かりやすいアドバイス
        """
```

### 4.2 データ永続化

#### 4.2.1 一時ストレージ設計

```python
class TemporaryImageStorage:
    """生成画像の一時保存サービス"""
    
    def __init__(self, storage_path: str, ttl: int = 3600):
        self.storage_path = storage_path
        self.ttl = ttl  # Time to live (秒)
    
    async def store_image(self, session_id: str, image_data: bytes) -> str:
        """画像を一時保存"""
        file_path = f"{self.storage_path}/{session_id}.jpg"
        
        with open(file_path, "wb") as f:
            f.write(image_data)
        
        # TTL管理のためのメタデータ保存
        await self._set_expiration(session_id)
        
        return file_path
    
    async def cleanup_expired(self):
        """期限切れ画像の削除"""
        # 定期実行で期限切れファイルを削除
        pass
```

## 5. UI/UX設計

### 5.1 Flutter画面設計

#### 5.1.1 AI ファッション生成画面

```dart
class AIFashionCoordinateScreen extends StatefulWidget {
  final PersonalColorType personalColorType;
  final File capturedPhoto;
  
  @override
  _AIFashionCoordinateScreenState createState() => 
      _AIFashionCoordinateScreenState();
}

class _AIFashionCoordinateScreenState 
    extends State<AIFashionCoordinateScreen> {
  
  late AIFashionCoordinateBloc _bloc;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('おすすめコーデ'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: BlocBuilder<AIFashionCoordinateBloc, AIFashionState>(
        builder: (context, state) {
          return _buildContent(state);
        },
      ),
    );
  }
  
  Widget _buildContent(AIFashionState state) {
    switch (state.runtimeType) {
      case AIFashionInitial:
        return _buildInitialView();
      case AIFashionGenerating:
        return _buildLoadingView(state as AIFashionGenerating);
      case AIFashionGenerated:
        return _buildResultView(state as AIFashionGenerated);
      case AIFashionError:
        return _buildErrorView(state as AIFashionError);
      default:
        return Container();
    }
  }
  
  Widget _buildLoadingView(AIFashionGenerating state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24),
        Text(
          state.currentStep,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (state.progress != null)
          Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(value: state.progress),
          ),
      ],
    );
  }
  
  Widget _buildResultView(AIFashionGenerated state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 生成画像表示
          _buildGeneratedImage(state.coordinate.generatedImage),
          
          SizedBox(height: 24),
          
          // 推薦理由
          _buildRecommendationSection(state.coordinate.recommendation),
          
          SizedBox(height: 16),
          
          // スタイリングポイント
          _buildStylingPointsSection(state.coordinate.stylingPoints),
          
          SizedBox(height: 24),
          
          // アクションボタン
          _buildActionButtons(state.coordinate),
        ],
      ),
    );
  }
  
  Widget _buildGeneratedImage(String base64Image) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          base64Decode(base64Image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  
  Widget _buildRecommendationSection(String recommendation) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '推薦理由',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              recommendation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStylingPointsSection(List<String> stylingPoints) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'スタイリングポイント',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: 12),
            ...stylingPoints.map((point) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      point,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
```

#### 5.1.2 状態管理 (BLoC パターン)

```dart
// Events
abstract class AIFashionEvent {}

class GenerateCoordinateEvent extends AIFashionEvent {
  final File photo;
  final PersonalColorType personalColorType;
  final StylePreference? stylePreference;
  
  GenerateCoordinateEvent({
    required this.photo,
    required this.personalColorType,
    this.stylePreference,
  });
}

class RetryGenerationEvent extends AIFashionEvent {}

// States
abstract class AIFashionState {}

class AIFashionInitial extends AIFashionState {}

class AIFashionGenerating extends AIFashionState {
  final String currentStep;
  final double? progress;
  
  AIFashionGenerating({
    required this.currentStep,
    this.progress,
  });
}

class AIFashionGenerated extends AIFashionState {
  final FashionCoordinate coordinate;
  
  AIFashionGenerated(this.coordinate);
}

class AIFashionError extends AIFashionState {
  final String message;
  final String? errorCode;
  
  AIFashionError({required this.message, this.errorCode});
}

// BLoC
class AIFashionCoordinateBloc 
    extends Bloc<AIFashionEvent, AIFashionState> {
  
  final AIFashionRepository repository;
  
  AIFashionCoordinateBloc({required this.repository}) 
      : super(AIFashionInitial()) {
    on<GenerateCoordinateEvent>(_onGenerateCoordinate);
    on<RetryGenerationEvent>(_onRetryGeneration);
  }
  
  Future<void> _onGenerateCoordinate(
    GenerateCoordinateEvent event,
    Emitter<AIFashionState> emit,
  ) async {
    emit(AIFashionGenerating(
      currentStep: '画像を解析しています...',
      progress: 0.1,
    ));
    
    try {
      emit(AIFashionGenerating(
        currentStep: '年齢を推定しています...',
        progress: 0.3,
      ));
      
      emit(AIFashionGenerating(
        currentStep: 'ファッション画像を生成しています...',
        progress: 0.6,
      ));
      
      emit(AIFashionGenerating(
        currentStep: '推薦理由を生成しています...',
        progress: 0.9,
      ));
      
      final coordinate = await repository.generateCoordinate(
        photo: event.photo,
        personalColorType: event.personalColorType,
        stylePreference: event.stylePreference,
      );
      
      emit(AIFashionGenerated(coordinate));
      
    } catch (e) {
      emit(AIFashionError(
        message: _getErrorMessage(e),
        errorCode: _getErrorCode(e),
      ));
    }
  }
}
```

## 6. エラーハンドリング戦略

### 6.1 階層別エラー処理

#### 6.1.1 プレゼンテーション層
```dart
class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final String? errorCode;
  final VoidCallback? onRetry;
  
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(errorCode),
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('再試行'),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### 6.1.2 アプリケーション層
```python
class ErrorHandler:
    """統一エラーハンドリング"""
    
    @staticmethod
    def handle_ai_service_error(e: Exception) -> dict:
        """AI サービスエラーの処理"""
        if isinstance(e, ImagenQuotaExceeded):
            return {
                "code": "QUOTA_EXCEEDED",
                "message": "一時的にサービスが混み合っています。しばらく後にお試しください。"
            }
        elif isinstance(e, ImagenContentFiltered):
            return {
                "code": "INAPPROPRIATE_CONTENT",
                "message": "適切な画像を生成できませんでした。別の写真をお試しください。"
            }
        else:
            return {
                "code": "AI_SERVICE_UNAVAILABLE",
                "message": "AIサービスが一時的に利用できません。"
            }
```

## 7. テスト設計

### 7.1 テスト戦略

#### 7.1.1 ユニットテスト
```python
class TestAIFashionCoordinateService:
    
    @pytest.fixture
    def service(self):
        return AIFashionCoordinateService(
            imagen_service=Mock(),
            gemini_service=Mock(),
            age_estimation_service=Mock(),
            personal_color_service=Mock()
        )
    
    async def test_generate_coordinate_success(self, service):
        """正常なコーディネート生成のテスト"""
        # Given
        request = CoordinateRequest(
            user_photo=create_test_photo(),
            personal_color_type=PersonalColorType.SPRING
        )
        
        # When
        result = await service.generate_coordinate(request)
        
        # Then
        assert result.estimated_age > 0
        assert result.recommendation_reason
        assert len(result.styling_points) > 0
    
    async def test_generate_coordinate_with_invalid_image(self, service):
        """無効な画像でのテスト"""
        # Given
        request = CoordinateRequest(
            user_photo=create_invalid_photo(),
            personal_color_type=PersonalColorType.SPRING
        )
        
        # When & Then
        with pytest.raises(InvalidImageException):
            await service.generate_coordinate(request)
```

#### 7.1.2 統合テスト
```python
class TestAIFashionAPI:
    
    async def test_coordinate_generation_endpoint(self, client):
        """API エンドポイントの統合テスト"""
        # Given
        test_image = create_test_image()
        
        # When
        response = await client.post(
            "/api/v1/ai-coordinate",
            files={"image": test_image},
            data={"personal_color_type": "spring"}
        )
        
        # Then
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "generated_image" in data["data"]
        assert "recommendation" in data["data"]
```

### 7.2 パフォーマンステスト

```python
class TestPerformance:
    
    async def test_generation_time_within_limit(self):
        """生成時間の制限テスト"""
        start_time = time.time()
        
        # コーディネート生成実行
        result = await generate_coordinate_with_real_apis()
        
        end_time = time.time()
        generation_time = end_time - start_time
        
        assert generation_time < 90  # 90秒以内
```

## 8. デプロイメント設計

### 8.1 環境構成

#### 8.1.1 開発環境
```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  api:
    build: .
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - IMAGEN_API_KEY=${IMAGEN_API_KEY}
      - DEBUG=true
    volumes:
      - ./src:/app/src
      - ./temp_storage:/app/temp_storage
    ports:
      - "8000:8000"
```

#### 8.1.2 本番環境
```yaml
# Cloud Run 設定
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: ai-fashion-coordinate-api
spec:
  template:
    spec:
      containers:
      - image: gcr.io/project/ai-fashion-api
        env:
        - name: GEMINI_API_KEY
          valueFrom:
            secretKeyRef:
              name: ai-secrets
              key: gemini-api-key
        resources:
          limits:
            cpu: "2"
            memory: "4Gi"
          requests:
            cpu: "1"
            memory: "2Gi"
```

## 9. 監視・ロギング設計

### 9.1 メトリクス監視

```python
class MetricsCollector:
    """パフォーマンスメトリクス収集"""
    
    def __init__(self):
        self.generation_time = Histogram('generation_time_seconds')
        self.success_rate = Counter('generation_success_total')
        self.error_rate = Counter('generation_error_total')
    
    def record_generation_time(self, time_seconds: float):
        self.generation_time.observe(time_seconds)
    
    def record_success(self):
        self.success_rate.inc()
    
    def record_error(self, error_type: str):
        self.error_rate.labels(error_type=error_type).inc()
```

### 9.2 構造化ログ

```python
import structlog

logger = structlog.get_logger()

async def generate_coordinate_with_logging(request: CoordinateRequest):
    """ログ付きコーディネート生成"""
    
    logger.info(
        "coordinate_generation_started",
        personal_color_type=request.personal_color_type.value,
        has_style_preference=request.style_preference is not None
    )
    
    try:
        result = await generate_coordinate(request)
        
        logger.info(
            "coordinate_generation_completed",
            generation_time=result.metadata.generation_time,
            estimated_age=result.estimated_age
        )
        
        return result
        
    except Exception as e:
        logger.error(
            "coordinate_generation_failed",
            error_type=type(e).__name__,
            error_message=str(e)
        )
        raise
```

この技術設計書により、AI ファッションコーディネート生成機能の詳細な実装指針が明確になります。次のステップとして、この設計に基づいたタスク分解（tasks.md）の作成に進むことができます。
