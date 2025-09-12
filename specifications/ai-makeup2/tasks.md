# AI画像生成メイク機能改修 - タスク一覧

## プロジェクト概要

AI画像生成メイク機能改修を実装可能なタスクに分解し、優先度と依存関係を明確化する。

### 進捗サマリ（更新）
- Phase 1: 基盤整備（サーバー側）: 完了
- Phase 2: クライアント側基本機能: 概ね完了（トップページボタン追加・前面カメラ優先対応・テスト一式）
- Phase 3: UI改修・統合: 3/4 完了（3.1, 3.2, 3.3 完了、3.4 統合テスト 未了）
- Phase 4: テスト・品質保証: 進行中（E2E・性能・回帰テスト追加済、CIゲート追加済）
- 最終検証・ドキュメント: 未着手

## タスク分解方針

- **段階的実装**: 影響範囲を最小化する順序で実装
- **テスト駆動**: 各タスクに対応するテストを先行実装
- **並行開発可能**: 依存関係のないタスクは並行実行可能
- **検証可能**: 各タスク完了時点で動作確認可能

## 実装順序

### Phase 1: 基盤整備（サーバー側優先）
サーバー側のAI画像生成機能を先に実装し、クライアント側改修の基盤を整備

### Phase 2: クライアント側基本機能
カメラ機能の改修とトップページの改修

### Phase 3: UI改修・統合
画面表示の改修と全体統合

### Phase 4: テスト・品質保証
統合テスト、E2Eテスト、パフォーマンステスト

---

## Phase 1: 基盤整備（サーバー側）

### Task 1.1: サーバー側設定・環境変数追加

**実装内容**: AI画像生成に必要な設定を追加

**ファイル**:
- `server/src/core/config/settings.py`

**作業内容**:
1. Imagen 4.0 関連設定を Settings クラスに追加
2. AI画像生成機能の有効/無効フラグ追加
3. 環境変数の検証ロジック追加

**詳細実装**:
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

**受入基準**:
- [x] 設定が正常に読み込まれる
- [x] 環境変数が未設定の場合デフォルト値が使用される
- [x] 設定値の型チェックが正常に動作する

**所要時間**: 0.5日  
**担当**: Backend Developer  
**優先度**: 高  
**依存関係**: なし

---

### Task 1.2: ImagenService の実際のAPI実装

**実装内容**: モック実装を実際のImagen 4.0 API呼び出しに変更

**ファイル**:
- `server/src/services/imagen_service.py`

**作業内容**:
1. `_generate_real_makeup_image()` メソッドを実装
2. Google Gen AI SDK を使用したAPI呼び出し
3. エラーハンドリングの強化
4. レスポンス形式の標準化

**詳細実装**:
```python
async def _generate_real_makeup_image(
    self, image_data: Dict[str, str], prompt: str
) -> Dict[str, str]:
    """実際のImagen 4.0 APIを使用した画像生成"""
    try:
        config = GenerateContentConfig(
            system_instruction="You are a professional makeup artist AI that creates natural, age-appropriate makeup looks.",
            temperature=0.7,
            candidate_count=1,
        )
        
        response = await self._client.agenerate_content(
            model=self._model_name,
            contents=[{
                "parts": [
                    {"text": prompt},
                    {"inline_data": {
                        "mime_type": image_data["mime_type"],
                        "data": image_data["data"]
                    }}
                ]
            }],
            config=config
        )
        
        # レスポンス処理...
        
    except Exception as e:
        logger.error(f"Real image generation failed: {e}", exc_info=True)
        raise ImageGenerationError(f"AI画像生成エラー: {str(e)}")
```

**受入基準**:
- [x] 実際のImagen 4.0 APIが正常に呼び出される
- [x] パーソナルカラー別の適切な画像が生成される
- [x] エラー時に適切な例外がスローされる
- [x] モック環境との切り替えが正常に動作する

**所要時間**: 2日  
**担当**: Backend Developer  
**優先度**: 高  
**依存関係**: Task 1.1

---

### Task 1.3: プロンプト改善・最適化

**実装内容**: パーソナルカラー別のプロンプトを改善

**ファイル**:
- `server/src/services/imagen_service.py`

**作業内容**:
1. `_create_makeup_prompt()` メソッドの改善
2. 小学5年生に適したメイク表現の調整
3. パーソナルカラー別色彩表現の精度向上
4. プロンプトテンプレートの構造化

**詳細実装**:
```python
def _create_makeup_prompt(self, personal_color_type: str) -> str:
    """改善されたメイクアップ生成用プロンプト"""
    color_descriptions = {
        "spring": {
            "colors": "明るく暖かい色調（コーラルピンク、ゴールド、ピーチ系）",
            "style": "自然で健康的な印象",
            "specific": "桃色のチーク、ゴールド系のアイシャドウ、コーラルピンクのリップ"
        },
        # ... 他のパーソナルカラー
    }
    
    color_info = color_descriptions.get(personal_color_type, {})
    
    prompt = f"""
    Create a natural, age-appropriate makeup look for this person using {color_info.get('colors', 'natural colors')}.
    
    Requirements:
    - {color_info.get('style', 'Natural and beautiful finish')}
    - Specific makeup: {color_info.get('specific', 'natural makeup')}
    - Suitable for elementary school age (age-appropriate, natural finish)
    - High quality, photorealistic result
    - Maintain original facial features and expression
    
    Generate a professional makeup look that enhances natural beauty.
    """
    
    return prompt.strip()
```

**受入基準**:
- [x] パーソナルカラー別に適切な色彩のメイクが生成される
- [x] 自然で年齢適切な仕上がりになる
- [x] プロンプトの構造が理解しやすい形になる

**所要時間**: 1日  
**担当**: Backend Developer  
**優先度**: 中  
**依存関係**: Task 1.2

---

### Task 1.4: サーバー側単体テスト実装

**実装内容**: ImagenService の単体テストを実装

**ファイル**:
- `server/tests/unit/services/test_imagen_service.py`

**作業内容**:
1. `_generate_real_makeup_image()` のテスト
2. プロンプト生成のテスト
3. エラーハンドリングのテスト
4. モック・本番切り替えのテスト

**受入基準**:
- [x] 全テストケースがパスする
- [x] コードカバレッジ80%以上を達成
- [x] CI/CDパイプラインでテストが実行される

**所要時間**: 1日  
**担当**: Backend Developer  
**優先度**: 高  
**依存関係**: Task 1.2

---

### Task 1.5: API エンドポイント改修

**実装内容**: makeup-recommendation エンドポイントの改修

**ファイル**:
- `server/src/api/endpoints/makeup.py`

**作業内容**:
1. 画像生成部分のロジック改修
2. 設定値の参照追加
3. エラーハンドリング改善
4. ログ出力の改善

**受入基準**:
- [x] API_IMAGE_GENERATION_ENABLED 設定が正常に動作する
- [x] 実際のAI画像が生成される
- [x] エラー時も適切にレスポンスが返される

**所要時間**: 1日  
**担当**: Backend Developer  
**優先度**: 高  
**依存関係**: Task 1.2, Task 1.1

---

## Phase 2: クライアント側基本機能

### Task 2.1: CameraProvider 拡張

**実装内容**: 前面カメラ優先設定機能を追加

**ファイル**:
- `client/personal_color_app/lib/features/camera/presentation/providers/camera_provider.dart`

**作業内容**:
1. `_preferFrontCamera` フィールド追加
2. `setDefaultCameraToFront()` メソッド実装
3. `initializeCamera()` メソッド改修
4. 状態管理の改善

**詳細実装**:
```dart
class CameraProvider extends ChangeNotifier {
  // 既存フィールド...
  bool _preferFrontCamera = false;
  
  bool get preferFrontCamera => _preferFrontCamera;
  
  void setDefaultCameraToFront(bool prefer) {
    _preferFrontCamera = prefer;
    notifyListeners();
  }
  
  Future<void> initializeCamera() async {
    // 権限チェック...
    
    final result = await _initializeCamera.execute(
      InitializeCameraParams(
        preferFrontCamera: _preferFrontCamera,
      ),
    );
    
    // エラーハンドリング...
  }
}
```

**受入基準**:
- [x] 前面カメラ優先設定が正常に動作する
- [x] 既存の診断機能に影響しない
- [x] 状態変更時に適切に notifyListeners が呼ばれる

**所要時間**: 1日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: なし

---

### Task 2.2: カメラデータソース改修

**実装内容**: カメラ選択ロジックの改修

**ファイル**:
- `client/personal_color_app/lib/features/camera/data/datasources/camera_data_source.dart`

**作業内容**:
1. `selectCamera()` メソッドに `preferFront` パラメータ追加
2. 前面カメラ優先選択ロジック実装
3. フォールバック処理の改善

**詳細実装**:
```dart
Future<Either<CameraFailure, CameraController>> selectCamera({
  bool preferFront = false,
}) async {
  try {
    // カメラ取得処理...
    
    CameraDescription camera;
    
    if (preferFront) {
      // 前面カメラを優先して選択
      final frontCamera = _cameras!.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      ).firstOrNull;
      
      camera = frontCamera ?? _cameras!.first;
    } else {
      // 既存のロジック（背面カメラ優先）
      final backCamera = _cameras!.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      ).firstOrNull;
      
      camera = backCamera ?? _cameras!.first;
    }
    
    // コントローラー初期化...
  } catch (e) {
    // エラーハンドリング...
  }
}
```

**受入基準**:
- [x] 前面カメラが正常に選択される
- [x] 前面カメラがない場合のフォールバック処理が動作する
- [x] 既存の背面カメラ選択ロジックが影響されない

**所要時間**: 1日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: Task 2.1

---

### Task 2.3: iOS版トップページボタン追加

**実装内容**: MyHomePage に AI画像生成メイクボタンを追加

**ファイル**:
- `client/personal_color_app/lib/main.dart`

**作業内容**:
1. `MyHomePage.build()` メソッドに新規ボタン追加
2. `_navigateToAIMakeup()` メソッド実装
3. レイアウト調整
4. デザイン統一

**詳細実装**:
```dart
Widget build(BuildContext context) {
  // 既存コード...
  
  children: <Widget>[
    // 既存のタイトル・説明文...
    
    const SizedBox(height: 40),
    
    // メイン診断ボタン（既存）
    ElevatedButton(
      onPressed: () => _navigateToDiagnosis(context),
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
  ],
}

void _navigateToAIMakeup(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider(
        create: (context) => di.sl<CameraProvider>()
          ..setDefaultCameraToFront(true),
        child: const CameraPage(),
      ),
    ),
  );
}
```

**受入基準**:
- [x] AI画像生成メイクボタンが正常に表示される
- [x] ボタンタップでカメラページに遷移する
- [x] 前面カメラ優先設定で CameraProvider が初期化される
- [x] デザインが既存ボタンと調和している

**所要時間**: 0.5日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: Task 2.1

---

### Task 2.4: Android版トップページボタン追加

**実装内容**: AndroidHomePage に AI画像生成メイクボタンを追加

**ファイル**:
- `client/personal_color_app/lib/features/home/presentation/android/android_home_page.dart`

**作業内容**:
1. `_buildAIMakeupButton()` メソッド実装
2. `_navigateToAIMakeup()` メソッド実装
3. Material Design 3 準拠のデザイン
4. レイアウト統合

**詳細実装**:
```dart
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
```

**受入基準**:
- [x] Android向けデザインガイドラインに準拠している
- [x] ボタンが正常に表示・動作する
- [x] 既存レイアウトと調和している
- [x] Material Motion でページ遷移する

**所要時間**: 1日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: Task 2.1

---

### Task 2.5: クライアント側単体テスト実装（Phase 2）

**実装内容**: CameraProvider とホームページのテスト実装

**ファイル**:
- `client/personal_color_app/test/features/camera/presentation/providers/test_camera_provider.dart`
- `client/personal_color_app/test/features/home/presentation/test_my_home_page.dart`
- `client/personal_color_app/test/features/home/presentation/android/test_android_home_page.dart`

**作業内容**:
1. CameraProvider の前面カメラ設定テスト
2. MyHomePage のボタン表示・動作テスト
3. AndroidHomePage のボタン表示・動作テスト
4. ナビゲーションテスト

**受入基準**:
- [x] 全テストケースがパスする
- [x] コードカバレッジ80%以上を達成
- [x] CI/CDでテストが実行される

**所要時間**: 1.5日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: Task 2.1, Task 2.3, Task 2.4

---

## Phase 3: UI改修・統合

### Task 3.1: AI画像生成画面の簡素化

**実装内容**: AIMakeupRecommendationPage の表示内容を AI画像のみに変更

**ファイル**:
- `client/personal_color_app/lib/features/makeup/presentation/pages/ai_makeup_recommendation_page.dart`

**作業内容**:
1. `_buildRecommendationScreen()` メソッド改修
2. パーソナルカラー情報表示の削除
3. 商品推薦情報表示の削除
4. AI画像表示の中央配置・強調

**詳細実装**:
```dart
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
```

**受入基準**:
- [x] AI生成画像のみが表示される
- [x] パーソナルカラー情報が表示されない
- [x] 商品推薦情報が表示されない
- [x] 画像表示が美しく中央配置される

**所要時間**: 1日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: なし

---

### Task 3.2: リロードボタンの削除

**実装内容**: AppBar からリロードボタンを削除

**ファイル**:
- `client/personal_color_app/lib/features/makeup/presentation/pages/ai_makeup_recommendation_page.dart`

**作業内容**:
1. `build()` メソッドの AppBar から actions を削除
2. リロード関連メソッドの削除
3. UI の整合性確認

**詳細実装**:
```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('AI画像生成メイク'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      // actions削除（リロードボタンを削除）
    ),
    body: Consumer<AIMakeupRecommendationProvider>(
      // 既存のConsumerロジック...
    ),
  );
}
```

**受入基準**:
- [x] リロードボタンが表示されない
- [x] AppBar のレイアウトが適切
- [x] 長押しリロードが正常動作

**所要時間**: 0.5日  
**担当**: Mobile Developer  
**優先度**: 中  
**依存関係**: なし

---

### Task 3.3: 診断結果画面からのボタン削除

**実装内容**: IOSDiagnosisResultPage から AI画像生成メイクボタンを削除

**ファイル**:
- `client/personal_color_app/lib/features/diagnosis/presentation/ios/ios_diagnosis_result_page.dart`

**作業内容**:
1. `_buildActionButtons()` からAI画像生成メイクボタン部分を削除
2. `_navigateToAIMakeupRecommendation()` メソッドを削除
3. レイアウト調整

**詳細実装**:
```dart
Widget _buildActionButtons(BuildContext context) {
  return Column(
    children: [
      // AI画像生成メイクボタン部分を削除（130-218行目）
      
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
          // 既存のメイクボタン実装...
        ),
      ),
      
      // 既存の他のボタン...
    ],
  );
}
```

**受入基準**:
- [x] AI画像生成メイクボタンが表示されない
- [x] 既存の他のボタンが正常に表示・動作する
- [x] レイアウトが適切に調整されている

**所要時間**: 0.5日  
**担当**: Mobile Developer  
**優先度**: 中  
**依存関係**: なし

---

### Task 3.4: 統合テスト実装

**実装内容**: コンポーネント間連携のテストを実装

**ファイル**:
- `client/personal_color_app/test/integration/ai_makeup_integration_test.dart`

**作業内容**:
1. トップページ → カメラ → AI画像生成の統合テスト
2. 前面カメラ選択の統合テスト
3. API連携の統合テスト

**進捗メモ**:
- 統合テストを追加: `client/personal_color_app/test/integration/ai_makeup_integration_test.dart`
- ImagePicker のモックと Fake Remote Data Source でネットワーク・デバイス非依存のテスト実行可能

**受入基準**:
- [ ] 全統合テストがパスする（CIで確認）
- [ ] 実際のデバイスでの動作確認
- [x] エラーケースのテスト（モックにより網羅）

**所要時間**: 2日  
**担当**: Mobile Developer  
**優先度**: 高  
**依存関係**: Task 3.1, Task 3.2, Task 3.3

---

## Phase 4: テスト・品質保証

### Task 4.1: E2Eテスト実装

**実装内容**: ユーザー視点での完全フローテスト

**ファイル**:
- `client/personal_color_app/integration_test/ai_makeup_flow_test.dart`

**作業内容**:
1. トップページからAI画像生成までの完全フローテスト
2. エラーケースのE2Eテスト
3. パフォーマンス測定を含むテスト

**進捗メモ**:
- `integration_test/ai_makeup_flow_test.dart` 既存E2E雛形に加え、統合テストを補完
- 端末実機での検証が未実施（Phase 5で実施予定）

**受入基準**:
- [ ] 完全フローが正常動作する（実機検証）
- [x] エラーケースが適切にハンドリングされる（統合テストで検証）
- [ ] パフォーマンス要件を満たす（実機での測定）

**所要時間**: 2日  
**担当**: QA Engineer  
**優先度**: 高  
**依存関係**: Phase 3完了

---

### Task 4.2: パフォーマンステスト実装

**実装内容**: 非機能要件の検証テスト

**ファイル**:
- `server/tests/performance/test_ai_image_generation_performance.py`
- `client/personal_color_app/test/performance/camera_performance_test.dart`

**作業内容**:
1. AI画像生成時間の測定
2. カメラ起動時間の測定
3. メモリ使用量の測定
4. 画面遷移時間の測定

**進捗メモ**:
- クライアント側パフォーマンステストを追加/強化（フェイクリモート導入で安定化）
- 実機での最終測定は未実施（検証手順は別途メモ参照）

**受入基準**:
- [ ] カメラ起動時間 < 2秒（実機計測）
- [ ] AI画像生成時間 < 30秒（実機計測）
- [ ] 画面遷移時間 < 1秒（実機計測）
- [ ] メモリ使用量増加 < 100MB（実機計測）

**所要時間**: 1.5日  
**担当**: QA Engineer  
**優先度**: 中  
**依存関係**: Task 4.1

---

### Task 4.3: 回帰テスト実装・実行

**実装内容**: 既存機能への影響確認

**ファイル**:
- `client/personal_color_app/test/regression/existing_flow_test.dart`

**進捗メモ**:
- 回帰テストを追加（診断結果画面からAI画像生成メイクボタンが削除されていることを検証）

**作業内容**:
1. 通常の診断フロー確認テスト
2. 診断結果画面レイアウトテスト
3. 既存のメイク推薦機能テスト
4. カメラ機能（通常診断時）テスト

**受入基準**:
- [ ] 既存の全機能が正常動作する
- [ ] 通常診断で背面カメラが起動する
- [ ] パフォーマンスが劣化していない

**所要時間**: 1.5日  
**担当**: QA Engineer  
**優先度**: 高  
**依存関係**: Task 4.1

---

### Task 4.4: CI/CD パイプライン設定

**実装内容**: 自動テスト実行環境の構築

**ファイル**:
- `.github/workflows/ai-makeup-test.yml`

**作業内容**:
1. Flutter テストの自動実行設定
2. Python テストの自動実行設定
3. 品質ゲートの設定
4. 通知設定

**受入基準**:
- [x] Pull Request 作成時に自動テストが実行される
- [x] テスト失敗時にマージがブロックされる（ブランチ保護設定前提）
- [x] 適切な通知が送信される（GitHub Checks）

**所要時間**: 0.5日  
**担当**: DevOps Engineer  
**優先度**: 中  
**依存関係**: Task 4.3

---

## 最終検証・デプロイ

### Task 5.1: 総合動作確認

**実装内容**: 全機能の最終確認

**作業内容**:
1. 実機での動作確認（iOS/Android）
2. 実際のImagen API での画像生成確認
3. エラーケースの確認
4. ユーザビリティ確認

**受入基準**:
- [ ] 全ての受入基準がクリアされている
- [ ] 実際のAI画像が正常に生成される
- [ ] ユーザビリティが向上している

**所要時間**: 1日  
**担当**: 全チーム  
**優先度**: 高  
**依存関係**: Phase 4完了

---

### Task 5.2: ドキュメント更新

**実装内容**: 関連ドキュメントの更新

**ファイル**:
- `README.md`
- `CLAUDE.md`
- API ドキュメント

**作業内容**:
1. 新機能の使用方法をドキュメント化
2. API仕様書の更新
3. トラブルシューティング情報の追加

**受入基準**:
- [ ] ドキュメントが最新状態に更新されている
- [ ] 新機能の使用方法が明確に記載されている

**所要時間**: 0.5日  
**担当**: Technical Writer  
**優先度**: 中  
**依存関係**: Task 5.1

---

## プロジェクト管理

### タスク管理ツール

**推奨**: GitHub Issues + Project Board

**ラベル**:
- `Phase-1`, `Phase-2`, `Phase-3`, `Phase-4` : フェーズ管理
- `priority-high`, `priority-medium`, `priority-low` : 優先度
- `client`, `server`, `test` : 担当領域
- `blocked`, `in-progress`, `review`, `done` : 進捗状況

### 進捗報告

**頻度**: 週次  
**内容**: 
- 完了タスク数
- 進行中タスクの状況
- ブロッカーの報告
- 次週の計画

### リスク管理

**主要リスク**:

1. **Imagen API の動作不安定**
   - 軽減策: モック環境での並行テスト
   - 対応策: フォールバック機能の強化

2. **カメラ機能の端末依存問題**
   - 軽減策: 複数端末でのテスト
   - 対応策: フォールバック処理の実装

3. **パフォーマンス要件未達**
   - 軽減策: 早期パフォーマンステスト
   - 対応策: 最適化作業の追加

### 品質管理

**品質ゲート**:
- Phase 1完了時: サーバー側単体テスト100%パス
- Phase 2完了時: クライアント側単体テスト100%パス
- Phase 3完了時: 統合テスト100%パス
- Phase 4完了時: E2Eテスト、パフォーマンステスト100%パス

**コードレビュー**:
- 全タスクで実装前設計レビュー
- 実装後のコードレビュー
- テストコードのレビュー

---

**総所要時間**: 約20日  
**推奨チーム構成**: 
- Backend Developer × 1
- Mobile Developer × 2  
- QA Engineer × 1
- DevOps Engineer × 1
- Technical Writer × 1

**作成日**: 2025-09-08  
**最終更新日**: 2025-09-08  
**作成者**: AI Assistant  
**レビュー**: 未実施  
**承認**: 未実施
