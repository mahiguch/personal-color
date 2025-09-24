"""
Personal Color Analysis Prompt Management
パーソナルカラー診断用のプロンプト管理クラス
"""

from typing import Dict, Any, Optional
import json
import logging

logger = logging.getLogger(__name__)


class PersonalColorPrompt:
    """パーソナルカラー診断用プロンプト管理クラス"""

    def __init__(self):
        self.base_prompt = self._get_base_analysis_prompt()
        self.error_prompts = self._get_error_prompts()

    def create_analysis_prompt(self, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        診断用プロンプトを生成

        Args:
            metadata: 追加のメタデータ

        Returns:
            str: 生成されたプロンプト
        """
        prompt = self.base_prompt

        # メタデータがある場合は追加情報として含める
        if metadata:
            additional_info = self._format_metadata_info(metadata)
            if additional_info:
                prompt += f"\n\n【追加情報】\n{additional_info}"

        return prompt

    def create_enhanced_analysis_prompt(self, metadata: Optional[Dict[str, Any]] = None) -> str:
        """
        年齢・性別推定を含む統合分析プロンプトを生成

        Args:
            metadata: 追加のメタデータ

        Returns:
            str: 生成されたプロンプト
        """
        prompt = """あなたはパーソナルカラー診断と年齢・性別推定の専門家です。

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

        # メタデータがある場合は追加情報として含める
        if metadata:
            additional_info = self._format_metadata_info(metadata)
            if additional_info:
                prompt += f"\n\n【追加情報】\n{additional_info}"

        return prompt

    def _get_base_analysis_prompt(self) -> str:
        """基本の診断プロンプトを取得"""
        return """あなたは小学5年生にもわかりやすく説明できる、パーソナルカラー診断の専門家です。

以下の画像を分析して、その人に最も似合うパーソナルカラーを診断してください。

【分析ポイント】
1. 肌の色合い（イエローベース・ブルーベース）
2. 髪の色と質感
3. 瞳の色
4. 全体的な印象と調和

【診断結果の4つのタイプ】
- Spring（春）: 明るく華やかな色が似合う、イエローベース
- Summer（夏）: 上品で涼しげな色が似合う、ブルーベース
- Autumn（秋）: 深みのある暖かい色が似合う、イエローベース
- Winter（冬）: はっきりした鮮やかな色が似合う、ブルーベース

【重要な注意事項】
- 診断結果への自信度（confidence）は70-95%の範囲で設定する
- 小学5年生でも理解できる優しい言葉で説明する
- ポジティブで励ましの気持ちを込める
- 必ずJSON形式で回答し、他の文章は含めない

【回答形式】
必ず以下のJSON形式で回答してください：

{
  "personal_color_type": "Spring",
  "confidence": 85,
  "explanation": "あなたの肌は暖かみのあるイエローベースで、明るい髪色と優しい瞳の色をしています。きらきらした明るい色がとても似合います！",
  "recommended_colors": ["コーラルピンク", "イエローグリーン", "アクアブルー", "ピーチ", "ライトブラウン"],
  "tips": ["明るい色の服を着ると、あなたの元気で素敵な魅力がもっと輝きます！", "アクセサリーはゴールド系がおすすめです", "メイクは透明感のある仕上がりを心がけてみてください"]
}

画像を分析して、上記の形式で診断結果を教えてください。"""

    def _get_error_prompts(self) -> Dict[str, str]:
        """エラーケース用プロンプトを取得"""
        return {
            "no_face_detected": """画像から人の顔を検出できませんでした。

{
  "error": "顔が見つかりません",
  "message": "写真にお顔がはっきり写るように、もう一度撮影してみてください！",
  "suggestions": ["明るい場所で撮影する", "カメラに近づく", "正面を向く"]
}""",
            "poor_image_quality": """画像の品質が診断に不十分です。

{
  "error": "画像が不鮮明です", 
  "message": "もう少し明るくはっきりとした写真で、もう一度お試しください！",
  "suggestions": ["自然光の当たる場所で撮影する", "カメラを安定させる", "ピントを合わせる"]
}""",
            "multiple_faces": """複数の顔が検出されました。

{
  "error": "複数の人が写っています",
  "message": "診断は一人ずつ行います。一人だけが写った写真で撮影してください！", 
  "suggestions": ["一人で撮影する", "背景に他の人が写らないようにする"]
}""",
        }

    def _format_metadata_info(self, metadata: Dict[str, Any]) -> str:
        """メタデータを追加情報として整形"""
        info_parts = []

        # アプリバージョン情報
        if "app_version" in metadata:
            info_parts.append(f"アプリバージョン: {metadata['app_version']}")

        # プラットフォーム情報
        if "platform" in metadata:
            info_parts.append(f"プラットフォーム: {metadata['platform']}")

        # タイムスタンプ
        if "timestamp" in metadata:
            info_parts.append(f"撮影時刻: {metadata['timestamp']}")

        # ユーザーからの追加情報
        if "user_notes" in metadata:
            info_parts.append(f"ユーザーメモ: {metadata['user_notes']}")

        return "\n".join(info_parts) if info_parts else ""

    def get_error_prompt(self, error_type: str) -> str:
        """指定されたエラータイプのプロンプトを取得"""
        return self.error_prompts.get(
            error_type, self.error_prompts["poor_image_quality"]
        )

    def validate_response_format(self, response_text: str) -> bool:
        """
        レスポンス形式の検証

        Args:
            response_text: Geminiからのレスポンステキスト

        Returns:
            bool: 正しい形式かどうか
        """
        try:
            # JSONの抽出と解析
            json_start = response_text.find("{")
            json_end = response_text.rfind("}") + 1

            if json_start == -1 or json_end <= json_start:
                return False

            json_text = response_text[json_start:json_end]
            result_data = json.loads(json_text)

            # 必須フィールドのチェック
            required_fields = [
                "personal_color_type",
                "confidence",
                "explanation",
                "recommended_colors",
                "tips",
            ]

            for field in required_fields:
                if field not in result_data:
                    logger.warning(f"Missing required field: {field}")
                    return False

            # データ型チェック
            if not isinstance(result_data["confidence"], (int, float)):
                return False

            if not isinstance(result_data["recommended_colors"], list):
                return False

            if not isinstance(result_data["tips"], list):
                return False

            # パーソナルカラータイプの検証
            valid_types = ["Spring", "Summer", "Autumn", "Winter"]
            if result_data["personal_color_type"] not in valid_types:
                return False

            return True

        except (json.JSONDecodeError, KeyError, TypeError) as e:
            logger.error(f"Response format validation failed: {e}")
            return False

    def validate_enhanced_response_format(self, response_text: str) -> bool:
        """
        拡張レスポンス形式の検証（年齢・性別推定含む）

        Args:
            response_text: Geminiからのレスポンステキスト

        Returns:
            bool: 正しい形式かどうか
        """
        try:
            # デバッグ用: レスポンス全文をログ出力
            logger.info(f"Validating enhanced response: {response_text}")
            
            # JSON の抽出と解析
            json_start = response_text.find("{")
            json_end = response_text.rfind("}") + 1

            if json_start == -1 or json_end <= json_start:
                logger.warning("No valid JSON structure found in response")
                return False

            json_text = response_text[json_start:json_end]
            logger.info(f"Extracted JSON text: {json_text}")
            result_data = json.loads(json_text)

            # 必須フィールドのチェック
            required_fields = [
                "personal_color_type",
                "confidence",
                "explanation",
                "recommended_colors",
                "tips",
                "person_analysis",
            ]

            for field in required_fields:
                if field not in result_data:
                    logger.warning(f"Missing required field: {field}")
                    return False

            # パーソナルカラー部分の検証（既存ロジックを再利用）
            if not self.validate_response_format(response_text):
                logger.warning("Basic personal color format validation failed")
                return False

            # person_analysis部分の検証
            person_analysis = result_data["person_analysis"]
            if not isinstance(person_analysis, dict):
                logger.warning(f"person_analysis is not a dictionary: {type(person_analysis)}")
                return False

            # person_analysis必須フィールド
            person_required_fields = ["age_group", "gender", "confidence"]
            for field in person_required_fields:
                if field not in person_analysis:
                    logger.warning(f"Missing required person_analysis field: {field}")
                    return False

            # age_group検証
            valid_age_groups = ["child", "student", "adult", "middleAge", "senior"]
            if person_analysis["age_group"] not in valid_age_groups:
                logger.warning(f"Invalid age_group: '{person_analysis['age_group']}', valid values: {valid_age_groups}")
                return False

            # gender検証
            valid_genders = ["male", "female", "unknown"]
            if person_analysis["gender"] not in valid_genders:
                logger.warning(f"Invalid gender: '{person_analysis['gender']}', valid values: {valid_genders}")
                return False

            # confidence検証（0-100の範囲）
            if not isinstance(person_analysis["confidence"], (int, float)):
                logger.warning(f"person_analysis confidence is not numeric: {type(person_analysis['confidence'])}")
                return False

            if not (0 <= person_analysis["confidence"] <= 100):
                logger.warning(f"person_analysis confidence out of range: {person_analysis['confidence']} (should be 0-100)")
                return False

            logger.info("Enhanced response format validation passed")
            return True

        except json.JSONDecodeError as e:
            logger.error(f"JSON parsing failed in enhanced response validation: {e}")
            return False
        except (KeyError, TypeError) as e:
            logger.error(f"Enhanced response format validation failed: {e}")
            return False
