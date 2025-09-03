"""
Geminiプロンプトテスト実行スクリプト

パーソナルカラー診断プロンプトの精度と小学5年生向けの説明品質をテストする
"""

import json
import asyncio
import base64
import os
from pathlib import Path
from typing import Dict, List, Optional
from dotenv import load_dotenv
import vertexai
from vertexai.generative_models import GenerativeModel, Part
from src.config.test_config import VertexAIConfig, TestConfig
from src.prompts.personal_color_analysis import PersonalColorPrompt

# .env ファイルを読み込み
load_dotenv()

# テスト用データ定義
EXPECTED_RESULTS = {
    "spring": {
        "personal_color_type": "Spring",
        "explanation": "明るく華やかな色が似合う",
    },
    "summer": {
        "personal_color_type": "Summer", 
        "explanation": "上品で涼しげな色が似合う",
    },
    "autumn": {
        "personal_color_type": "Autumn",
        "explanation": "深みのある暖かい色が似合う", 
    },
    "winter": {
        "personal_color_type": "Winter",
        "explanation": "はっきりした鮮やかな色が似合う",
    },
}

SAMPLE_IMAGES = {
    "spring_type": "test_images/spring_sample.jpg",
    "summer_type": "test_images/summer_sample.jpg", 
    "autumn_type": "test_images/autumn_sample.jpg",
    "winter_type": "test_images/winter_sample.jpg",
    "poor_quality": "test_images/blurry_sample.jpg",
    "no_face": "test_images/no_face_sample.jpg",
}


class GeminiPromptTester:
    def __init__(self):
        """テスター初期化"""
        self.model = None
        self.test_results = []
        self.prompt_manager = PersonalColorPrompt()
        # 設定クラスから値を取得
        self.project_id = VertexAIConfig.PROJECT_ID
        self.location = VertexAIConfig.LOCATION
        self.model_name = VertexAIConfig.MODEL_NAME

    async def initialize(self):
        """Vertex AI初期化"""
        try:
            vertexai.init(project=self.project_id, location=self.location)
            self.model = GenerativeModel(self.model_name)
            print("✅ Vertex AI初期化完了")
        except Exception as e:
            print(f"❌ Vertex AI初期化エラー: {e}")
            raise

    def load_image_as_base64(self, image_path: str) -> Optional[str]:
        """画像をBase64形式で読み込み"""
        try:
            with open(image_path, "rb") as image_file:
                return base64.b64encode(image_file.read()).decode("utf-8")
        except FileNotFoundError:
            print(f"⚠️ 画像ファイルが見つかりません: {image_path}")
            return None
        except Exception as e:
            print(f"❌ 画像読み込みエラー: {e}")
            return None

    async def test_personal_color_analysis(
        self, image_path: str, expected_type: str
    ) -> Dict:
        """パーソナルカラー診断テスト"""
        print(f"\n🧪 テスト実行: {image_path}")

        # 画像読み込み
        image_data = self.load_image_as_base64(image_path)
        if not image_data:
            return {"error": "画像読み込み失敗", "image_path": image_path}

        try:
            # Geminiに送信
            prompt = self.prompt_manager.create_analysis_prompt()
            image_part = Part.from_data(
                data=base64.b64decode(image_data), mime_type="image/jpeg"
            )

            response = await self.model.generate_content_async([prompt, image_part])

            # レスポンス解析
            response_text = response.text.strip()

            # JSON抽出
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                json_text = response_text[json_start:json_end].strip()
            else:
                json_text = response_text

            # JSON解析
            try:
                result = json.loads(json_text)
            except json.JSONDecodeError as e:
                return {
                    "error": "JSON解析エラー",
                    "raw_response": response_text,
                    "json_error": str(e),
                }

            # 結果評価
            evaluation = self.evaluate_result(result, expected_type)

            return {
                "image_path": image_path,
                "expected_type": expected_type,
                "result": result,
                "evaluation": evaluation,
                "raw_response": response_text,
            }

        except Exception as e:
            print(f"❌ Gemini API詳細エラー: {type(e).__name__}: {str(e)}")
            import traceback

            traceback.print_exc()
            return {
                "error": "Gemini API エラー",
                "image_path": image_path,
                "exception": str(e),
            }

    def evaluate_result(self, result: Dict, expected_type: str) -> Dict:
        """診断結果の評価"""
        evaluation = {
            "accuracy_score": 0,
            "explanation_quality": 0,
            "format_compliance": 0,
            "child_friendliness": 0,
            "issues": [],
        }

        expected = EXPECTED_RESULTS.get(expected_type, {})

        # 1. 診断精度評価 (40点)
        if "personal_color_type" in result:
            if result["personal_color_type"] == expected.get("personal_color_type"):
                evaluation["accuracy_score"] = 40
            else:
                evaluation["issues"].append(
                    f"診断結果が期待値と異なる: {result['personal_color_type']} != {expected.get('personal_color_type')}"
                )
        else:
            evaluation["issues"].append("personal_color_type フィールドがない")

        # 2. 説明品質評価 (25点)
        if "explanation" in result:
            explanation = result["explanation"]
            quality_score = 0

            # 小学5年生向けの言葉使いかチェック
            difficult_words = ["アンダートーン", "彩度", "明度", "色相"]
            if not any(word in explanation for word in difficult_words):
                quality_score += 10

            # ポジティブな表現かチェック
            positive_words = ["素敵", "美しい", "似合う", "輝く", "魅力"]
            if any(word in explanation for word in positive_words):
                quality_score += 10

            # 適切な長さかチェック（50-150文字）
            if 50 <= len(explanation) <= 150:
                quality_score += 5

            evaluation["explanation_quality"] = quality_score
        else:
            evaluation["issues"].append("explanation フィールドがない")

        # 3. フォーマット準拠評価 (20点)
        required_fields = [
            "personal_color_type",
            "confidence",
            "explanation",
            "recommended_colors",
            "tips",
        ]
        present_fields = sum(1 for field in required_fields if field in result)
        evaluation["format_compliance"] = int(
            (present_fields / len(required_fields)) * 20
        )

        if present_fields < len(required_fields):
            missing = [field for field in required_fields if field not in result]
            evaluation["issues"].append(f"必須フィールド不足: {missing}")

        # 4. 子ども向け配慮評価 (15点)
        child_score = 0

        # 信頼度が適切な範囲か
        if "confidence" in result and 70 <= result["confidence"] <= 95:
            child_score += 5

        # おすすめ色の説明があるか
        if "recommended_colors" in result and len(result["recommended_colors"]) >= 3:
            child_score += 5

        # 励ましのメッセージがあるか
        if "tips" in result and result["tips"]:
            child_score += 5

        evaluation["child_friendliness"] = child_score

        # 総合スコア計算
        total_score = sum(
            [
                evaluation["accuracy_score"],
                evaluation["explanation_quality"],
                evaluation["format_compliance"],
                evaluation["child_friendliness"],
            ]
        )
        evaluation["total_score"] = total_score
        evaluation["percentage"] = round((total_score / 100) * 100, 1)

        return evaluation

    async def run_comprehensive_test(self):
        """包括的テスト実行"""
        print("🚀 Geminiプロンプト包括テスト開始")
        print("=" * 50)

        # テスト画像サンプル作成（実際の画像がない場合のダミー）
        self.create_sample_images()

        # 各パーソナルカラータイプのテスト
        for image_type, image_path in SAMPLE_IMAGES.items():
            if image_type in ["poor_quality", "no_face"]:
                continue  # エラーケースは別途テスト

            expected_type = image_type.replace("_type", "")
            test_result = await self.test_personal_color_analysis(
                image_path, expected_type
            )
            self.test_results.append(test_result)

        # 結果レポート生成
        self.generate_test_report()

    def create_sample_images(self):
        """テスト用サンプル画像作成（ダミー画像）"""
        test_images_dir = Path("test_images")
        test_images_dir.mkdir(exist_ok=True)

        # 実際のテストでは本物の画像を用意してください
        sample_image_info = """
        📸 テスト用画像の準備が必要です：
        
        test_images/spring_sample.jpg  - スプリングタイプの人の顔写真
        test_images/summer_sample.jpg  - サマータイプの人の顔写真  
        test_images/autumn_sample.jpg  - オータムタイプの人の顔写真
        test_images/winter_sample.jpg  - ウィンタータイプの人の顔写真
        test_images/blurry_sample.jpg  - ぼやけた画像
        test_images/no_face_sample.jpg - 顔が写っていない画像
        
        上記の画像を用意してからテストを実行してください。
        """

        with open(test_images_dir / "README.md", "w", encoding="utf-8") as f:
            f.write(sample_image_info)

        print("📝 test_images/README.md を作成しました")
        print("📸 テスト用画像を test_images/ フォルダに配置してください")

    def generate_test_report(self):
        """テスト結果レポート生成"""
        print("\n📊 テスト結果レポート")
        print("=" * 50)

        if not self.test_results:
            print("❌ テスト結果がありません（画像ファイルが見つからない可能性があります）")
            return

        total_tests = len(self.test_results)
        successful_tests = sum(
            1 for result in self.test_results if "error" not in result
        )

        print(f"総テスト数: {total_tests}")
        print(f"成功テスト: {successful_tests}")
        print(f"成功率: {(successful_tests/total_tests)*100:.1f}%")
        print()

        # 個別結果
        for i, result in enumerate(self.test_results, 1):
            print(f"【テスト {i}】")

            if "error" in result:
                print(f"❌ エラー: {result['error']}")
                print(f"   画像: {result.get('image_path', 'N/A')}")
            else:
                eval_data = result["evaluation"]
                print(f"✅ 画像: {result['image_path']}")
                print(f"   期待タイプ: {result['expected_type']}")
                print(f"   診断結果: {result['result'].get('personal_color_type', 'N/A')}")
                print(f"   総合スコア: {eval_data['percentage']}%")
                print(f"   精度: {eval_data['accuracy_score']}/40")
                print(f"   説明品質: {eval_data['explanation_quality']}/25")
                print(f"   フォーマット: {eval_data['format_compliance']}/20")
                print(f"   子ども配慮: {eval_data['child_friendliness']}/15")

                if eval_data["issues"]:
                    print(f"   課題: {', '.join(eval_data['issues'])}")
            print()

        # 改善提案
        self.generate_improvement_suggestions()

    def generate_improvement_suggestions(self):
        """改善提案生成"""
        print("💡 改善提案")
        print("=" * 30)

        if not self.test_results:
            return

        # 共通課題の抽出
        all_issues = []
        low_scores = []

        for result in self.test_results:
            if "evaluation" in result:
                eval_data = result["evaluation"]
                all_issues.extend(eval_data.get("issues", []))

                if eval_data["percentage"] < 80:
                    low_scores.append(result)

        # 頻出課題
        from collections import Counter

        issue_counts = Counter(all_issues)

        if issue_counts:
            print("🔍 頻出課題:")
            for issue, count in issue_counts.most_common(3):
                print(f"   • {issue} ({count}回)")
            print()

        # 低スコア分析
        if low_scores:
            print("⚠️ 改善が必要な項目:")
            avg_accuracy = sum(
                r["evaluation"]["accuracy_score"] for r in low_scores
            ) / len(low_scores)
            avg_explanation = sum(
                r["evaluation"]["explanation_quality"] for r in low_scores
            ) / len(low_scores)

            if avg_accuracy < 30:
                print("   • 診断精度の向上が必要 - プロンプトの詳細化を検討")
            if avg_explanation < 20:
                print("   • 説明品質の向上が必要 - 小学生向け表現の改善")
            print()

        print("📋 推奨アクション:")
        print("   1. 診断精度向上: プロンプトに具体的な判定基準を追加")
        print("   2. 表現改善: 小学5年生レベルの語彙に調整")
        print("   3. フォーマット統一: JSON構造の検証を強化")
        print("   4. テストデータ拡充: より多様な画像でのテスト実行")


async def main():
    """メイン実行関数"""
    tester = GeminiPromptTester()

    try:
        await tester.initialize()
        await tester.run_comprehensive_test()
    except Exception as e:
        print(f"❌ テスト実行エラー: {e}")
        print("🔧 PROJECT_ID の設定とVertex AI APIの有効化を確認してください")


if __name__ == "__main__":
    asyncio.run(main())
