"""
パーソナルカラー診断用Geminiプロンプト設計

小学5年生向けのわかりやすいパーソナルカラー診断を提供するためのプロンプト管理モジュール
"""

# パーソナルカラー診断プロンプトテンプレート
PERSONAL_COLOR_ANALYSIS_PROMPT = """あなたは小学5年生にもわかりやすく説明できる、パーソナルカラー診断の専門家です。

以下の画像を分析して、その人に最も似合うパーソナルカラーを診断してください。

【分析ポイント】
1. 肌の色合い（イエローベース・ブルーベース）
2. 髪の色と質感
3. 瞳の色
4. 全体的な印象

【診断結果の4つのタイプ】
- スプリング（春）: 明るく華やかな色が似合う
- サマー（夏）: 上品で涼しげな色が似合う  
- オータム（秋）: 深みのある暖かい色が似合う
- ウィンター（冬）: はっきりした鮮やかな色が似合う

【回答形式】
必ず以下のJSON形式で回答してください：

```json
{
  "diagnosis_result": "スプリング",
  "confidence": 85,
  "explanation": "あなたの肌は暖かみのあるイエローベースで、明るい髪色と優しい瞳の色をしています。きらきらした明るい色がとても似合います！",
  "recommended_colors": [
    {"color_name": "コーラルピンク", "reason": "肌を明るく見せてくれる"},
    {"color_name": "イエローグリーン", "reason": "自然な魅力を引き出す"},
    {"color_name": "アクアブルー", "reason": "瞳を美しく見せる"}
  ],
  "avoid_colors": [
    {"color_name": "ダークネイビー", "reason": "肌がくすんで見える"},
    {"color_name": "モノトーン", "reason": "元気な印象が弱くなる"}
  ],
  "tips": "明るい色の服を着ると、あなたの元気で素敵な魅力がもっと輝きます！"
}
```

【重要な注意事項】
- 回答は必ず小学5年生でも理解できる優しい言葉で説明する
- 診断結果への自信度（confidence）は70-95%の範囲で設定する
- ネガティブな表現は避け、ポジティブで励ましの気持ちを込める
- 医学的・科学的根拠は求めず、楽しいエンターテイメントとして提供する
- 必ずJSON形式で回答し、他の文章は含めない

画像を分析して、上記の形式で診断結果を教えてください。"""

# エラーケース対応プロンプト
ERROR_CASE_PROMPTS = {
    "no_face_detected": """画像から人の顔を検出できませんでした。

```json
{
  "error": "顔が見つかりません",
  "message": "写真にお顔がはっきり写るように、もう一度撮影してみてください！",
  "suggestions": [
    "明るい場所で撮影する",
    "カメラに近づく",
    "正面を向く"
  ]
}
```""",
    
    "poor_image_quality": """画像の品質が診断に不十分です。

```json
{
  "error": "画像が不鮮明です",
  "message": "もう少し明るくはっきりとした写真で、もう一度お試しください！",
  "suggestions": [
    "自然光の当たる場所で撮影する",
    "カメラを安定させる",
    "ピントを合わせる"
  ]
}
```""",
    
    "multiple_faces": """複数の顔が検出されました。

```json
{
  "error": "複数の人が写っています",
  "message": "診断は一人ずつ行います。一人だけが写った写真で撮影してください！",
  "suggestions": [
    "一人で撮影する",
    "背景に他の人が写らないようにする"
  ]
}
```"""
}

# 診断精度向上のための補助プロンプト
ACCURACY_ENHANCEMENT_PROMPTS = {
    "lighting_analysis": """この画像の照明条件を分析してください：
- 自然光/人工光の判定
- 色温度の推定
- 肌色に与える影響の評価
照明による色の歪みを考慮して診断精度を調整してください。""",
    
    "skin_tone_analysis": """肌の色調をより詳細に分析してください：
- アンダートーン（イエロー/ピンク/ニュートラル）の判定
- 肌の明度レベル
- 彩度の特徴
これらの要素を総合してパーソナルカラータイプを決定してください。""",
    
    "feature_consistency": """以下の特徴の一貫性を確認してください：
- 肌・髪・瞳の色の調和
- 全体的な色彩バランス
- パーソナルカラータイプとの適合性
一貫性のない要素がある場合、最も支配的な特徴に基づいて診断してください。"""
}

def get_analysis_prompt(include_enhancements=True):
    """診断用プロンプトを取得"""
    base_prompt = PERSONAL_COLOR_ANALYSIS_PROMPT
    
    if include_enhancements:
        enhancement_texts = "\n\n".join([
            "【追加分析項目】",
            ACCURACY_ENHANCEMENT_PROMPTS["lighting_analysis"],
            ACCURACY_ENHANCEMENT_PROMPTS["skin_tone_analysis"], 
            ACCURACY_ENHANCEMENT_PROMPTS["feature_consistency"]
        ])
        return f"{base_prompt}\n\n{enhancement_texts}"
    
    return base_prompt

def get_error_prompt(error_type):
    """エラーケース用プロンプトを取得"""
    return ERROR_CASE_PROMPTS.get(error_type, ERROR_CASE_PROMPTS["poor_image_quality"])

# テスト用のサンプル画像パス（開発時用）
SAMPLE_IMAGES = {
    "spring_type": "test_images/spring_sample.jpg",
    "summer_type": "test_images/summer_sample.jpg", 
    "autumn_type": "test_images/autumn_sample.jpg",
    "winter_type": "test_images/winter_sample.jpg",
    "poor_quality": "test_images/blurry_sample.jpg",
    "no_face": "test_images/no_face_sample.jpg"
}

# 期待される診断結果（テスト用）
EXPECTED_RESULTS = {
    "spring_type": {
        "diagnosis_result": "スプリング",
        "confidence_min": 70,
        "should_contain": ["明るい", "華やか", "イエローベース"]
    },
    "summer_type": {
        "diagnosis_result": "サマー", 
        "confidence_min": 70,
        "should_contain": ["上品", "涼しげ", "ブルーベース"]
    },
    "autumn_type": {
        "diagnosis_result": "オータム",
        "confidence_min": 70,
        "should_contain": ["深み", "暖かい", "イエローベース"]
    },
    "winter_type": {
        "diagnosis_result": "ウィンター",
        "confidence_min": 70, 
        "should_contain": ["はっきり", "鮮やか", "ブルーベース"]
    }
}
