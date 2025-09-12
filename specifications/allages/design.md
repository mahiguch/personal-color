# 全年齢対応パーソナルカラー診断 - 技術設計書

## 概要

年齢と性別推定機能を追加し、全年齢層に対応したパーソナライズされた診断結果を提供するための技術設計を定義する。

## アーキテクチャ設計

### 1. システム全体構成

```
Client (Flutter)          Server (Python)
┌─────────────────┐       ┌─────────────────┐
│ Camera Capture  │ ----> │ Image Analysis  │
│                 │       │ (Gemini Vision) │
├─────────────────┤       ├─────────────────┤
│ DiagnosisResult │ <---- │ Combined Result │
│ + PersonAnalysis│       │ Generation      │
├─────────────────┤       ├─────────────────┤
│ Adaptive UI     │       │ Prompt Engine   │
│ Rendering       │       │ (Age/Gender)    │
└─────────────────┘       └─────────────────┘
```

### 2. データフロー

```
1. Image Capture (Client) 
   ↓
2. Single API Call (Client → Server)
   ↓
3. Gemini Vision Analysis (Server)
   - Personal Color Detection
   - Age Group Estimation  
   - Gender Estimation
   ↓
4. Adaptive Content Generation (Server)
   - Age-specific explanation
   - Gender-specific advice
   ↓
5. Enhanced Response (Server → Client)
   ↓
6. Adaptive UI Rendering (Client)
```

## データ構造設計

### 1. 新規エンティティ

#### AgeGroup (Flutter)
```dart
/// 年代区分
enum AgeGroup {
  child,    // 8-12歳: 現在の小学生向けスタイル
  student,  // 13-22歳: トレンド志向、ポップな表現
  adult,    // 23-39歳: 実用的、プロフェッショナル
  middleAge,// 40-59歳: 上品、大人の魅力重視
  senior,   // 60歳以上: 気品、健康的な印象重視
}

extension AgeGroupExtension on AgeGroup {
  String get displayName {
    switch (this) {
      case AgeGroup.child: return '子供';
      case AgeGroup.student: return '学生';
      case AgeGroup.adult: return '社会人';
      case AgeGroup.middleAge: return '中高年';
      case AgeGroup.senior: return 'シニア';
    }
  }
  
  String get apiValue {
    switch (this) {
      case AgeGroup.child: return 'child';
      case AgeGroup.student: return 'student';
      case AgeGroup.adult: return 'adult';
      case AgeGroup.middleAge: return 'middleAge';
      case AgeGroup.senior: return 'senior';
    }
  }
}
```

#### Gender (Flutter)
```dart
/// 性別区分
enum Gender {
  male,     // 男性: ファッション実用性重視
  female,   // 女性: 詳細な色彩理論とメイク・ファッション
  unknown,  // 不明: 中性的な表現
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male: return '男性';
      case Gender.female: return '女性';
      case Gender.unknown: return '不明';
    }
  }
  
  String get apiValue {
    switch (this) {
      case Gender.male: return 'male';
      case Gender.female: return 'female';
      case Gender.unknown: return 'unknown';
    }
  }
}
```

#### PersonAnalysis (Flutter)
```dart
/// 人物分析結果
class PersonAnalysis extends Equatable {
  const PersonAnalysis({
    required this.ageGroup,
    required this.gender,
    required this.confidence,
  });

  /// 推定年代
  final AgeGroup ageGroup;

  /// 推定性別
  final Gender gender;

  /// 推定精度 (0-100)
  final int confidence;

  @override
  List<Object> get props => [ageGroup, gender, confidence];

  /// JSONから作成
  factory PersonAnalysis.fromJson(Map<String, dynamic> json) {
    return PersonAnalysis(
      ageGroup: AgeGroup.values.firstWhere(
        (e) => e.apiValue == json['age_group'],
        orElse: () => AgeGroup.child,
      ),
      gender: Gender.values.firstWhere(
        (e) => e.apiValue == json['gender'],
        orElse: () => Gender.unknown,
      ),
      confidence: json['confidence'] as int,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'age_group': ageGroup.apiValue,
      'gender': gender.apiValue,
      'confidence': confidence,
    };
  }
}
```

### 2. 既存エンティティの拡張

#### DiagnosisResult (Flutter)
```dart
/// 拡張された診断結果エンティティ
class DiagnosisResult extends Equatable {
  const DiagnosisResult({
    required this.diagnosisType,
    required this.confidence,
    required this.explanation,
    required this.recommendedColors,
    required this.avoidColors,
    required this.tips,
    this.personAnalysis,  // 新規追加
    this.requestId,
    this.processingTimeMs,
  });

  // 既存フィールド
  final PersonalColorType diagnosisType;
  final int confidence;
  final String explanation;
  final List<ColorRecommendation> recommendedColors;
  final List<ColorRecommendation> avoidColors;
  final String tips;
  final String? requestId;
  final int? processingTimeMs;

  /// 新規追加: 人物分析結果
  final PersonAnalysis? personAnalysis;

  @override
  List<Object?> get props => [
        diagnosisType,
        confidence,
        explanation,
        recommendedColors,
        avoidColors,
        tips,
        personAnalysis,  // 追加
        requestId,
        processingTimeMs,
      ];

  /// 年代・性別情報が利用可能かどうか
  bool get hasPersonAnalysis => personAnalysis != null;

  /// 適応化された説明文かどうか
  bool get isAdaptiveContent => hasPersonAnalysis && explanation.isNotEmpty;
}
```

## サーバー側設計

### 1. プロンプト設計

#### PersonalColorAnalysisPrompt拡張 (Python)
```python
class PersonalColorPrompt:
    def create_enhanced_analysis_prompt(self, metadata: Optional[Dict[str, Any]] = None) -> str:
        """年齢・性別推定を含む統合分析プロンプトを生成"""
        return """あなたはパーソナルカラー診断と年齢・性別推定の専門家です。

以下の画像を分析して、その人に最も似合うパーソナルカラーと、年代・性別を推定してください。

【分析ポイント】
1. パーソナルカラー分析
   - 肌の色合い（イエローベース・ブルーベース）
   - 髪の色と質感
   - 瞳の色
   - 全体的な印象と調和

2. 年代推定（年代区分のみ）
   - child (8-12歳): 子供らしい特徴
   - student (13-22歳): 若々しい特徴
   - adult (23-39歳): 成人の特徴
   - middleAge (40-59歳): 中高年の特徴
   - senior (60歳以上): シニアの特徴

3. 性別推定
   - male: 男性的特徴
   - female: 女性的特徴
   - unknown: 判断困難な場合

【診断結果の4つのタイプ】
- Spring（春）: 明るく華やかな色が似合う、イエローベース
- Summer（夏）: 上品で涼しげな色が似合う、ブルーベース
- Autumn（秋）: 深みのある暖かい色が似合う、イエローベース
- Winter（冬）: はっきりした鮮やかな色が似合う、ブルーベース

【適応的説明文の生成ルール】
年代と性別の組み合わせに応じて、以下の方針で説明文を生成してください：

- child: 楽しく分かりやすい表現、カラフルな例
- student: トレンド感、ポップな表現
- adult: 実用的、ビジネスシーン対応
- middleAge: 上品で落ち着いた表現
- senior: 気品のある健康的な表現

- male: ファッション実用性重視、シンプルな表現
- female: 詳細な色彩理論、メイク・ファッション両方
- unknown: 中性的でどちらにも適用可能な表現

【回答形式】
必ず以下のJSON形式で回答してください：

{
  "personal_color_type": "Spring",
  "confidence": 85,
  "explanation": "年代・性別に適応した説明文",
  "recommended_colors": ["色名1", "色名2", ...],
  "tips": ["アドバイス1", "アドバイス2", ...],
  "person_analysis": {
    "age_group": "adult",
    "gender": "female", 
    "confidence": 78
  }
}"""

    def get_adaptive_explanation_template(self, age_group: str, gender: str, 
                                        personal_color: str) -> str:
        """年代・性別に応じた説明文テンプレートを取得"""
        templates = {
            # Child templates
            ("child", "male"): "きみの肌は{base_tone}で、{color_characteristic}！",
            ("child", "female"): "あなたの肌は{base_tone}で、{color_characteristic}よ！",
            ("child", "unknown"): "あなたの肌は{base_tone}で、{color_characteristic}！",
            
            # Student templates  
            ("student", "male"): "君の肌は{base_tone}系で、{color_characteristic}タイプだね。",
            ("student", "female"): "あなたの肌は{base_tone}系で、{color_characteristic}タイプです。",
            ("student", "unknown"): "あなたの肌は{base_tone}系で、{color_characteristic}タイプです。",
            
            # Adult templates
            ("adult", "male"): "あなたの肌色は{base_tone}で、{color_characteristic}スタイルが最適です。",
            ("adult", "female"): "あなたの美しい肌は{base_tone}で、{color_characteristic}カラーが魅力を引き立てます。",
            ("adult", "unknown"): "あなたの肌色は{base_tone}で、{color_characteristic}スタイルが似合います。",
            
            # MiddleAge templates
            ("middleAge", "male"): "あなたの落ち着いた肌色は{base_tone}で、{color_characteristic}な色合いが品格を演出します。",
            ("middleAge", "female"): "あなたの上品な肌は{base_tone}で、{color_characteristic}カラーが大人の魅力を際立たせます。",
            ("middleAge", "unknown"): "あなたの肌色は{base_tone}で、{color_characteristic}な色合いが品のある印象を作ります。",
            
            # Senior templates
            ("senior", "male"): "あなたの成熟した肌色は{base_tone}で、{color_characteristic}色が健康的で上品な印象を与えます。",
            ("senior", "female"): "あなたの気品ある肌は{base_tone}で、{color_characteristic}カラーが若々しい輝きをもたらします。",
            ("senior", "unknown"): "あなたの肌色は{base_tone}で、{color_characteristic}色が活き活きとした印象を演出します。",
        }
        
        return templates.get((age_group, gender), templates[("adult", "unknown")])
```

### 2. API設計

#### 診断エンドポイント拡張
```python
# server/src/api/endpoints/diagnosis.py

@router.post("/diagnose-enhanced", response_model=EnhancedDiagnosisResponse)
async def diagnose_personal_color_enhanced(request: DiagnosisRequest):
    """年齢・性別推定を含む統合パーソナルカラー診断"""
    try:
        # 画像をBase64デコード
        image_data = base64.b64decode(request.image_data)
        
        # Gemini Vision統合分析
        gemini_service = get_gemini_service()
        analysis_result = await gemini_service.analyze_personal_color_with_demographics(
            image_data, 
            request.metadata
        )
        
        # レスポンス構築
        return EnhancedDiagnosisResponse(
            personal_color_type=analysis_result["personal_color_type"],
            confidence=analysis_result["confidence"],
            explanation=analysis_result["explanation"],
            recommended_colors=analysis_result["recommended_colors"],
            tips=analysis_result["tips"],
            person_analysis=PersonAnalysisResponse(
                age_group=analysis_result["person_analysis"]["age_group"],
                gender=analysis_result["person_analysis"]["gender"],
                confidence=analysis_result["person_analysis"]["confidence"]
            ),
            processing_time_ms=int(time.time() * 1000 - start_time),
            request_id=str(uuid.uuid4())
        )
        
    except Exception as e:
        logger.error(f"Enhanced diagnosis failed: {e}")
        raise HTTPException(status_code=500, detail="診断に失敗しました")
```

### 3. GeminiService拡張

```python
# server/src/services/gemini_service.py

class GeminiService:
    async def analyze_personal_color_with_demographics(
        self, 
        image_data: bytes, 
        metadata: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """パーソナルカラー診断と年齢・性別推定の統合分析"""
        try:
            # Base64エンコード
            base64_image = base64.b64encode(image_data).decode('utf-8')
            
            # 統合分析プロンプトを生成
            prompt_manager = PersonalColorPrompt()
            analysis_prompt = prompt_manager.create_enhanced_analysis_prompt(metadata)
            
            # Gemini Vision API呼び出し
            response = await self._call_gemini_vision(
                prompt=analysis_prompt,
                image_data=base64_image,
                max_retries=3
            )
            
            # レスポンス解析
            result = self._parse_enhanced_response(response)
            
            # 適応的説明文生成
            if "person_analysis" in result:
                result = self._enhance_with_adaptive_content(result)
            
            return result
            
        except Exception as e:
            logger.error(f"Demographic analysis failed: {e}")
            raise
    
    def _parse_enhanced_response(self, response_text: str) -> Dict[str, Any]:
        """拡張レスポンスの解析"""
        try:
            # JSON抽出
            json_start = response_text.find("{")
            json_end = response_text.rfind("}") + 1
            json_text = response_text[json_start:json_end]
            result = json.loads(json_text)
            
            # 必須フィールド検証
            required_fields = [
                "personal_color_type", "confidence", "explanation",
                "recommended_colors", "tips", "person_analysis"
            ]
            
            for field in required_fields:
                if field not in result:
                    raise ValueError(f"Missing required field: {field}")
            
            # person_analysis検証
            person_analysis = result["person_analysis"]
            if not all(key in person_analysis for key in ["age_group", "gender", "confidence"]):
                raise ValueError("Invalid person_analysis structure")
            
            return result
            
        except (json.JSONDecodeError, ValueError, KeyError) as e:
            logger.error(f"Enhanced response parsing failed: {e}")
            raise
    
    def _enhance_with_adaptive_content(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """適応的コンテンツで結果を強化"""
        person_analysis = result["person_analysis"]
        age_group = person_analysis["age_group"]
        gender = person_analysis["gender"]
        
        # 年代・性別別のアドバイス拡張
        adaptive_tips = self._get_adaptive_tips(age_group, gender, result["personal_color_type"])
        result["tips"].extend(adaptive_tips)
        
        return result
    
    def _get_adaptive_tips(self, age_group: str, gender: str, color_type: str) -> List[str]:
        """年代・性別に応じた追加アドバイス"""
        tip_templates = {
            ("child", "male"): [
                "学校でも使いやすい色を選ぼう！",
                "スポーツをするときにも似合う色だよ"
            ],
            ("child", "female"): [
                "友達と一緒におしゃれを楽しもう！",
                "発表会や特別な日にもぴったりな色よ"
            ],
            ("student", "male"): [
                "カジュアルスタイルに取り入れやすい色です",
                "就活シーンでも使える落ち着いた色も考慮してみてください"
            ],
            ("student", "female"): [
                "トレンドを意識したコーディネートに活用できます",
                "メイクにも取り入れて個性を表現してみてください"
            ],
            ("adult", "male"): [
                "ビジネスシーンでの印象アップに効果的です",
                "プライベートでも使い回しの利く実用的な色選びを"
            ],
            ("adult", "female"): [
                "職場での信頼感を高める色使いができます",
                "メイクとファッションのトータルコーディネートを意識して"
            ],
            ("middleAge", "male"): [
                "品格のある大人の魅力を引き出す色です",
                "落ち着いた中にも洗練された印象を作れます"
            ],
            ("middleAge", "female"): [
                "上品で洗練された大人の女性らしさが際立ちます",
                "年齢に応じた美しさを表現する色選びを心がけてください"
            ],
            ("senior", "male"): [
                "健康的で若々しい印象を演出できる色です",
                "品のある紳士らしい魅力を引き立てます"
            ],
            ("senior", "female"): [
                "気品と活力を同時に表現できる素晴らしい色です",
                "年齢を重ねた美しさを輝かせる色使いを楽しんでください"
            ]
        }
        
        return tip_templates.get((age_group, gender), [
            "あなたに似合う色を日常に取り入れてみてください",
            "色の力で、より魅力的な印象を演出できます"
        ])
```

## クライアント側設計

### 1. Repository Layer拡張

```dart
// lib/features/diagnosis/domain/repositories/diagnosis_repository.dart

abstract class DiagnosisRepository {
  Future<Either<Failure, DiagnosisResult>> diagnosePersonalColor(String imagePath);
  
  // 新規追加
  Future<Either<Failure, DiagnosisResult>> diagnosePersonalColorEnhanced(String imagePath);
}
```

### 2. UseCase拡張

```dart
// lib/features/diagnosis/domain/usecases/diagnose_personal_color_enhanced.dart

class DiagnosePersonalColorEnhanced implements UseCase<DiagnosisResult, DiagnosePersonalColorParams> {
  final DiagnosisRepository repository;

  DiagnosePersonalColorEnhanced(this.repository);

  @override
  Future<Either<Failure, DiagnosisResult>> call(DiagnosePersonalColorParams params) async {
    return await repository.diagnosePersonalColorEnhanced(params.imagePath);
  }
}

class DiagnosePersonalColorParams extends Equatable {
  final String imagePath;
  final Map<String, dynamic>? metadata;

  const DiagnosePersonalColorParams({
    required this.imagePath,
    this.metadata,
  });

  @override
  List<Object?> get props => [imagePath, metadata];
}
```

### 3. UI Layer拡張

#### 診断結果画面の拡張
```dart
// lib/features/diagnosis/presentation/ios/ios_diagnosis_result_page.dart

class IosDiagnosisResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildResultContent(context),
    );
  }

  Widget _buildResultContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMainResult(context),
          if (result.hasPersonAnalysis) _buildPersonAnalysisSection(context),
          _buildColorRecommendations(context),
          _buildTipsSection(context),
          _buildAIMakeupButton(context),
        ],
      ),
    );
  }

  Widget _buildPersonAnalysisSection(BuildContext context) {
    if (!result.hasPersonAnalysis) return const SizedBox.shrink();
    
    final personAnalysis = result.personAnalysis!;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '推定情報',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('年代', personAnalysis.ageGroup.displayName),
                const SizedBox(width: 8),
                _buildInfoChip('性別', personAnalysis.gender.displayName),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '推定精度: ${personAnalysis.confidence}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'この情報は診断結果の説明をパーソナライズするために使用されます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
```

### 4. 設定画面追加

```dart
// lib/features/settings/presentation/pages/privacy_settings_page.dart

class PrivacySettingsPage extends StatefulWidget {
  @override
  _PrivacySettingsPageState createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _showAgeGenderInfo = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシー設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '推定情報の表示',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('年代・性別情報を表示'),
                    subtitle: const Text('診断結果に推定された年代・性別情報を表示します'),
                    value: _showAgeGenderInfo,
                    onChanged: (value) {
                      setState(() {
                        _showAgeGenderInfo = value;
                      });
                      _savePrivacySettings();
                    },
                  ),
                  const Divider(),
                  Text(
                    'プライバシーについて',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 年代・性別の推定は、診断結果の説明をより適切にするためのものです\n'
                    '• 具体的な年齢ではなく、年代区分での推定を行います\n'
                    '• この情報は端末に保存され、外部に送信されることはありません\n'
                    '• いつでも表示のオン・オフを切り替えできます',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePrivacySettings() {
    // SharedPreferencesに保存
    // TODO: 実装
  }
}
```

## テスト設計

### 1. ユニットテスト

#### PersonAnalysisテスト (Flutter)
```dart
// test/features/diagnosis/domain/entities/person_analysis_test.dart

void main() {
  group('PersonAnalysis', () {
    test('should create PersonAnalysis from valid JSON', () {
      // Arrange
      final json = {
        'age_group': 'adult',
        'gender': 'female',
        'confidence': 85,
      };

      // Act
      final result = PersonAnalysis.fromJson(json);

      // Assert
      expect(result.ageGroup, AgeGroup.adult);
      expect(result.gender, Gender.female);
      expect(result.confidence, 85);
    });

    test('should convert PersonAnalysis to JSON', () {
      // Arrange
      const personAnalysis = PersonAnalysis(
        ageGroup: AgeGroup.student,
        gender: Gender.male,
        confidence: 78,
      );

      // Act
      final json = personAnalysis.toJson();

      // Assert
      expect(json['age_group'], 'student');
      expect(json['gender'], 'male');
      expect(json['confidence'], 78);
    });
  });
}
```

#### GeminiService統合テスト (Python)
```python
# server/tests/unit/services/test_gemini_service_enhanced.py

class TestGeminiServiceEnhanced:
    @pytest.mark.asyncio
    async def test_analyze_personal_color_with_demographics_success(self):
        """年齢・性別推定統合分析の成功ケース"""
        # Arrange
        service = get_gemini_service()
        test_image = self._load_test_image("test_face.jpg")
        
        # Act
        result = await service.analyze_personal_color_with_demographics(test_image)
        
        # Assert
        assert "personal_color_type" in result
        assert "person_analysis" in result
        assert result["person_analysis"]["age_group"] in ["child", "student", "adult", "middleAge", "senior"]
        assert result["person_analysis"]["gender"] in ["male", "female", "unknown"]
        assert 0 <= result["person_analysis"]["confidence"] <= 100

    @pytest.mark.asyncio
    async def test_adaptive_content_generation(self):
        """適応的コンテンツ生成のテスト"""
        # Arrange
        service = get_gemini_service()
        mock_result = {
            "personal_color_type": "Spring",
            "tips": ["基本アドバイス"],
            "person_analysis": {
                "age_group": "adult",
                "gender": "female",
                "confidence": 85
            }
        }
        
        # Act
        enhanced_result = service._enhance_with_adaptive_content(mock_result)
        
        # Assert
        assert len(enhanced_result["tips"]) > 1
        assert any("職場" in tip for tip in enhanced_result["tips"])
```

### 2. 統合テスト

```python
# server/tests/integration/test_enhanced_diagnosis_api.py

class TestEnhancedDiagnosisAPI:
    def test_diagnose_enhanced_success(self, client, test_image_base64):
        """拡張診断APIの成功ケース"""
        # Arrange
        payload = {
            "image_data": test_image_base64,
            "metadata": {
                "platform": "ios",
                "app_version": "1.0.0"
            }
        }
        
        # Act
        response = client.post("/api/v1/diagnose-enhanced", json=payload)
        
        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "personal_color_type" in data
        assert "person_analysis" in data
        assert data["person_analysis"]["age_group"] is not None
        assert data["person_analysis"]["gender"] is not None
        assert isinstance(data["person_analysis"]["confidence"], int)
```

## 段階的リリース計画

### Phase 1: データ構造・API拡張
- [ ] Flutter側エンティティ追加
- [ ] Python側API拡張
- [ ] 基本的な年齢・性別推定機能
- [ ] 単体テスト実装

### Phase 2: UI拡張・適応的コンテンツ
- [ ] 診断結果画面の人物分析表示
- [ ] 適応的説明文生成
- [ ] プライバシー設定画面
- [ ] 統合テスト実装

### Phase 3: 最適化・精度向上
- [ ] プロンプトエンジニアリング最適化
- [ ] 推定精度の向上
- [ ] パフォーマンステスト
- [ ] A/Bテスト対応

### Phase 4: 本番リリース
- [ ] 機能フラグ管理
- [ ] 段階的ロールアウト
- [ ] ユーザーフィードバック収集
- [ ] 精度モニタリング

## 制約・考慮事項

### 1. プライバシー・GDPR対応
- 年代推定は区分単位（具体的年齢は推定しない）
- ユーザーが推定情報表示を制御可能
- データ最小化原則の遵守

### 2. パフォーマンス
- シングルパス処理による効率性
- 既存診断時間（2-5秒）の維持
- 推定失敗時のグレースフル・フォールバック

### 3. 精度要件
- 年代推定: 70%以上
- 性別推定: 80%以上
- パーソナルカラー診断精度の維持

### 4. 後方互換性
- 既存API（/diagnose）は維持
- 新規API（/diagnose-enhanced）を追加
- クライアント側は段階的移行

## 関連文書

- `requirements.md`: 機能要件定義
- `test_design.md`: テスト仕様（次作成予定）
- `tasks.md`: 実装タスク分解（次作成予定）
- `../initialize/`: 既存システム仕様書

## 更新履歴

| 日付 | バージョン | 変更内容 | 担当者 |
|------|------------|----------|--------|
| 2024-01-XX | 1.0 | 初版作成 | Claude |