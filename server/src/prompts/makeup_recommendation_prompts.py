"""
Gemini AI用メイクアップ推奨プロンプトテンプレート

小学5年生向けのわかりやすい言語レベルで、
パーソナルカラーに基づいた適切なメイクアップ推奨理由を生成します。
"""

from typing import Dict, List, Any
from dataclasses import dataclass
from enum import Enum


class PersonalColorType(str, Enum):
    """パーソナルカラータイプ"""

    SPRING = "spring"
    SUMMER = "summer"
    AUTUMN = "autumn"
    WINTER = "winter"


class MakeupCategory(str, Enum):
    """メイクアップカテゴリ"""

    EYESHADOW = "eyeshadow"
    CHEEK = "cheek"
    LIP = "lip"


@dataclass
class MakeupProduct:
    """メイクアップ商品情報"""

    id: str
    name: str
    brand: str
    category: str
    price: int
    description: str
    colors: List[str]


class MakeupRecommendationPrompts:
    """メイクアップ推奨プロンプト生成クラス"""

    # パーソナルカラータイプの特徴説明
    COLOR_TYPE_CHARACTERISTICS = {
        PersonalColorType.SPRING: {
            "skin_tone": "暖かくて明るい黄色味のある肌",
            "suitable_colors": "明るくて鮮やかな暖かい色（コーラル、ピーチ、明るいオレンジ、ゴールド）",
            "avoid_colors": "暗くて重い色、青みの強い色",
            "personality": "元気で明るい、フレッシュで若々しい印象",
        },
        PersonalColorType.SUMMER: {
            "skin_tone": "透明感のある涼しい青味がかった肌",
            "suitable_colors": "やわらかくて上品な涼しい色（ローズピンク、ラベンダー、ソフトブルー）",
            "avoid_colors": "黄色味の強い色、鮮やか過ぎる色",
            "personality": "上品で優雅、知的で洗練された印象",
        },
        PersonalColorType.AUTUMN: {
            "skin_tone": "深みのある暖かい黄色味の肌",
            "suitable_colors": "深くて豊かな秋の色（ディープオレンジ、ブラウン、テラコッタ、ゴールド）",
            "avoid_colors": "明るすぎる色、青みの強い色",
            "personality": "落ち着いて大人っぽい、温かくて親しみやすい印象",
        },
        PersonalColorType.WINTER: {
            "skin_tone": "クールで透明感があり、コントラストがはっきりした肌",
            "suitable_colors": "鮮やかで印象的な色（ルビーレッド、ネイビー、ブラック、シルバー）",
            "avoid_colors": "ぼんやりした色、黄色味の強い色",
            "personality": "クールでシャープ、印象的で洗練された印象",
        },
    }

    # カテゴリ別の効果説明
    CATEGORY_EFFECTS = {
        MakeupCategory.EYESHADOW: {
            "effect": "目元を魅力的に見せて、表情を明るくする",
            "usage": "まぶたに色を付けて、目を大きく美しく見せる",
            "importance": "顔の印象を決める大切な部分",
        },
        MakeupCategory.CHEEK: {
            "effect": "自然な血色感を与えて、健康的に見せる",
            "usage": "頬に色を付けて、顔に立体感と温かさを与える",
            "importance": "元気で可愛らしい印象を作る",
        },
        MakeupCategory.LIP: {
            "effect": "口元を美しく見せて、全体の印象をまとめる",
            "usage": "唇に色や潤いを与えて、魅力的な口元を演出",
            "importance": "笑顔をより素敵に見せる",
        },
    }

    @classmethod
    def generate_system_prompt(cls) -> str:
        """Gemini AIのシステムプロンプトを生成"""
        return """あなたは小学5年生向けのメイクアップアドバイザーです。
以下の条件でメイクアップ推奨理由を説明してください：

**言語レベル**:
- 小学5年生がわかる簡単な言葉を使う
- 3-4文程度の短い文章
- 漢字にはひらがなを併用（例：「似合う（にあう）」）
- ポジティブで優しい表現

**内容要件**:
- パーソナルカラーの特徴を簡潔に説明
- なぜその色が似合うのかの理由
- 使ったときの印象や効果
- 小学生が理解できる具体的な表現

**避けるべき表現**:
- 専門用語や難しい言葉
- 長すぎる説明
- ネガティブな表現
- 大人向けの内容

**トーン**:
- 明るく楽しい
- 励ましとほめを含む
- わくわくする気持ちになる"""

    @classmethod
    def generate_user_prompt(
        cls,
        personal_color_type: PersonalColorType,
        category: MakeupCategory,
        products: List[MakeupProduct],
    ) -> str:
        """ユーザープロンプトを生成"""

        characteristics = cls.COLOR_TYPE_CHARACTERISTICS[personal_color_type]
        category_info = cls.CATEGORY_EFFECTS[category]

        # 商品情報を整理
        product_colors = []
        for product in products:
            product_colors.extend(product.colors)
        unique_colors = list(set(product_colors))

        # カテゴリ名を日本語に変換
        category_japanese = {
            MakeupCategory.EYESHADOW: "アイシャドウ",
            MakeupCategory.CHEEK: "チーク",
            MakeupCategory.LIP: "リップ",
        }[category]

        # パーソナルカラータイプを日本語に変換
        color_type_japanese = {
            PersonalColorType.SPRING: "スプリング（春）",
            PersonalColorType.SUMMER: "サマー（夏）",
            PersonalColorType.AUTUMN: "オータム（秋）",
            PersonalColorType.WINTER: "ウィンター（冬）",
        }[personal_color_type]

        prompt = f"""パーソナルカラー診断の結果が「{color_type_japanese}タイプ」の小学5年生に、{category_japanese}の推奨理由を説明してください。

**パーソナルカラーの特徴**:
- 肌の特徴: {characteristics['skin_tone']}
- 似合う色: {characteristics['suitable_colors']}
- 印象: {characteristics['personality']}

**推奨商品の色**:
{', '.join(unique_colors[:5])}  # 最大5色まで

**説明してほしいポイント**:
1. なぜこの{category_japanese}の色が{color_type_japanese}タイプに似合うのか
2. この色を使うとどんな素敵な印象になるのか
3. 小学生でも楽しく使える理由

**文字数**: 80-120文字程度
**文章数**: 3-4文

小学5年生が「わあ、素敵！使ってみたい！」と思えるような、わくわくする説明をお願いします。"""

        return prompt

    @classmethod
    def generate_fallback_explanation(
        cls, personal_color_type: PersonalColorType, category: MakeupCategory
    ) -> str:
        """Gemini AIが利用できない場合のフォールバック説明文"""

        fallback_explanations = {
            PersonalColorType.SPRING: {
                MakeupCategory.EYESHADOW: "あなたのスプリングタイプには、明るくて温かい色がとても似合います。コーラルピンクやゴールドの色で、目元がきらきら輝いて見えますよ。元気で明るい印象になって、みんなが素敵だなって思ってくれるはずです。",
                MakeupCategory.CHEEK: "スプリングタイプのあなたには、ピーチやコーラルの色がぴったりです。自然な血色で、健康的で可愛らしい印象になります。笑顔がもっと素敵に見えて、お友達にもほめられそうですね。",
                MakeupCategory.LIP: "明るいコーラルピンクで、スプリングタイプの魅力をアップしましょう。この色は、あなたの肌を明るく見せてくれます。笑った時にとても素敵で、自信を持って笑顔になれますよ。",
            },
            PersonalColorType.SUMMER: {
                MakeupCategory.EYESHADOW: "サマータイプのあなたには、やわらかくて上品な色がとても似合います。ラベンダーやローズピンクで、目元が優雅で美しく見えます。知的で洗練された印象になって、とても素敵に仕上がりますよ。",
                MakeupCategory.CHEEK: "あなたのサマータイプには、ローズピンクがぴったりです。青みのある美しい色が、透明感のある肌をもっと綺麗に見せてくれます。上品で可愛らしい印象になりますね。",
                MakeupCategory.LIP: "サマータイプのあなたには、ローズ系の色がとても似合います。青みのあるピンクが、肌の美しさを引き立ててくれます。品のある美しい口元で、みんなが見とれてしまいそうです。",
            },
            PersonalColorType.AUTUMN: {
                MakeupCategory.EYESHADOW: "オータムタイプのあなたには、深くて豊かな色がとても似合います。ブラウンやオレンジの色で、目元に温かみと深みが生まれます。大人っぽくて魅力的な印象になりますよ。",
                MakeupCategory.CHEEK: "あなたのオータムタイプには、テラコッタやベージュピンクがぴったりです。深みのある暖かい色が、肌の豊かさを引き出してくれます。落ち着いて素敵な印象になりますね。",
                MakeupCategory.LIP: "オータムタイプのあなたには、深いオレンジやブラウンレッドがとても似合います。この色が、肌の温かさと調和して、大人っぽくて魅力的な口元を演出してくれます。",
            },
            PersonalColorType.WINTER: {
                MakeupCategory.EYESHADOW: "ウィンタータイプのあなたには、はっきりした印象的な色がとても似合います。ネイビーやシルバーで、目元がドラマティックで美しく見えます。クールで洗練された印象になりますよ。",
                MakeupCategory.CHEEK: "あなたのウィンタータイプには、ベリーやローズレッドがぴったりです。鮮やかで美しい色が、肌の透明感を際立たせてくれます。印象的で素敵な仕上がりになりますね。",
                MakeupCategory.LIP: "ウィンタータイプのあなたには、ルビーレッドやベリー系がとても似合います。鮮やかで印象的な色が、美しいコントラストを作って、魅力的な口元を演出してくれます。",
            },
        }

        return fallback_explanations[personal_color_type][category]

    @classmethod
    def validate_ai_response(cls, response: str) -> bool:
        """AI応答の品質を検証"""
        if not response or len(response.strip()) == 0:
            return False

        # 文字数チェック（50-200文字程度）
        if len(response) < 50 or len(response) > 200:
            return False

        # 不適切なキーワードチェック
        inappropriate_keywords = [
            "大人",
            "セクシー",
            "魅惑",
            "高価",
            "ブランド志向",
            "購入",
            "買う",
            "お金",
            "値段",
        ]

        for keyword in inappropriate_keywords:
            if keyword in response:
                return False

        # ポジティブキーワードの存在確認
        positive_keywords = [
            "似合う",
            "素敵",
            "きれい",
            "可愛い",
            "美しい",
            "輝く",
            "素晴らしい",
            "魅力",
            "印象",
            "おしゃれ",
        ]

        has_positive = any(keyword in response for keyword in positive_keywords)
        if not has_positive:
            return False

        return True


# プロンプトテスト用のサンプルデータ
SAMPLE_PRODUCTS = {
    PersonalColorType.SPRING: [
        MakeupProduct(
            id="spring_eye_001",
            name="コーラルピンクパレット",
            brand="サンプルブランド",
            category="eyeshadow",
            price=1500,
            description="明るく華やかなコーラルピンクのパレット",
            colors=["コーラルピンク", "ゴールドベージュ", "パールホワイト"],
        ),
        MakeupProduct(
            id="spring_cheek_001",
            name="ピーチブラッシュ",
            brand="サンプルブランド",
            category="cheek",
            price=1200,
            description="自然な血色感を与えるピーチカラー",
            colors=["ピーチピンク", "コーラル"],
        ),
        MakeupProduct(
            id="spring_lip_001",
            name="コーラルリップ",
            brand="サンプルブランド",
            category="lip",
            price=1800,
            description="明るく華やかなコーラルカラー",
            colors=["コーラルピンク", "ピーチ"],
        ),
    ]
}


def test_prompt_generation():
    """プロンプト生成のテスト関数"""
    prompts = MakeupRecommendationPrompts()

    # システムプロンプトテスト
    system_prompt = prompts.generate_system_prompt()
    print("=== System Prompt ===")
    print(system_prompt)
    print()

    # ユーザープロンプトテスト
    sample_products = SAMPLE_PRODUCTS[PersonalColorType.SPRING]
    eyeshadow_products = [p for p in sample_products if p.category == "eyeshadow"]

    user_prompt = prompts.generate_user_prompt(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW, eyeshadow_products
    )
    print("=== User Prompt (Spring Eyeshadow) ===")
    print(user_prompt)
    print()

    # フォールバック説明テスト
    fallback = prompts.generate_fallback_explanation(
        PersonalColorType.SPRING, MakeupCategory.EYESHADOW
    )
    print("=== Fallback Explanation ===")
    print(fallback)
    print(f"Length: {len(fallback)} characters")
    print(f"Validation: {prompts.validate_ai_response(fallback)}")


if __name__ == "__main__":
    test_prompt_generation()
