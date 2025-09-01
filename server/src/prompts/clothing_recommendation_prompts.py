"""
Gemini AI用衣料品推奨プロンプトテンプレート

小学5年生向けのわかりやすい言語レベルで、
パーソナルカラーに基づいた適切な衣料品推奨理由を生成します。
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


class ClothingCategory(str, Enum):
    """衣料品カテゴリ"""

    TOPS = "tops"
    BOTTOMS = "bottoms"
    ACCESSORIES = "accessories"


@dataclass
class ClothingProduct:
    """衣料品商品情報"""

    id: str
    name: str
    brand: str
    category: str
    price: int
    description: str
    colors: List[str]


class ClothingRecommendationPrompts:
    """衣料品推奨プロンプト生成クラス"""

    # パーソナルカラータイプの特徴説明
    COLOR_TYPE_CHARACTERISTICS = {
        PersonalColorType.SPRING: {
            "skin_tone": "暖かくて明るい黄色味のある肌",
            "suitable_colors": "明るくて鮮やかな暖かい色（ライトピンク、コーラル、ライトイエロー、アクアブルー）",
            "avoid_colors": "暗くて重い色、青みの強い色",
            "personality": "元気で明るい、フレッシュで若々しい印象",
            "style": "軽やかで活動的、春らしい明るいファッション",
        },
        PersonalColorType.SUMMER: {
            "skin_tone": "透明感のある涼しい青味がかった肌",
            "suitable_colors": "やわらかくて上品な涼しい色（ラベンダーグレー、ダスティピンク、ソフトブルー）",
            "avoid_colors": "黄色味の強い色、鮮やか過ぎる色",
            "personality": "上品で優雅、知的で洗練された印象",
            "style": "エレガントで落ち着いた、クールで上品なファッション",
        },
        PersonalColorType.AUTUMN: {
            "skin_tone": "深みのある暖かい黄色味の肌",
            "suitable_colors": "深くて豊かな秋の色（キャメル、オリーブグリーン、バーガンディ、テラコッタ）",
            "avoid_colors": "明るすぎる色、青みの強い色",
            "personality": "落ち着いて大人っぽい、温かくて親しみやすい印象",
            "style": "リッチで上質、アースカラーを活かしたファッション",
        },
        PersonalColorType.WINTER: {
            "skin_tone": "クールで透明感があり、コントラストがはっきりした肌",
            "suitable_colors": "鮮やかで印象的な色（ピュアホワイト、ジェットブラック、ロイヤルブルー、ディープレッド）",
            "avoid_colors": "ぼんやりした色、黄色味の強い色",
            "personality": "クールでシャープ、印象的で洗練された印象",
            "style": "モダンでスタイリッシュ、コントラストを活かしたファッション",
        },
    }

    # カテゴリ別の効果説明
    CATEGORY_EFFECTS = {
        ClothingCategory.TOPS: {
            "effect": "顔周りの印象を決める重要なアイテム",
            "usage": "肌色を美しく見せ、全体のコーディネートの中心となる",
            "importance": "パーソナルカラーが最も影響する部分",
        },
        ClothingCategory.BOTTOMS: {
            "effect": "スタイルアップと全体のバランスを整える",
            "usage": "トップスとの組み合わせで印象を調整する",
            "importance": "体型を美しく見せる効果",
        },
        ClothingCategory.ACCESSORIES: {
            "effect": "コーディネートにアクセントを加える",
            "usage": "パーソナルカラーに合わせて顔映りを良くする",
            "importance": "小さなアイテムで大きな印象の変化を作る",
        },
    }

    @classmethod
    def generate_prompt(
        cls,
        personal_color_type: PersonalColorType,
        category: ClothingCategory,
        products: List[Dict[str, Any]],
    ) -> str:
        """衣料品推奨理由生成用のプロンプトを作成"""

        characteristics = cls.COLOR_TYPE_CHARACTERISTICS[personal_color_type]
        category_info = cls.CATEGORY_EFFECTS[category]

        # 商品情報をテキストに変換
        products_text = ""
        for i, product in enumerate(products, 1):
            colors_text = "、".join(product.get("colors", []))
            products_text += f"{i}. {product.get('name', '')} ({product.get('brand', '')}) - {colors_text}\n"

        prompt = f"""
あなたは小学5年生でもわかる、やさしいファッションアドバイザーです。

【パーソナルカラー診断結果】
タイプ: {personal_color_type.value.title()}タイプ
肌の特徴: {characteristics['skin_tone']}
似合う色: {characteristics['suitable_colors']}
スタイル: {characteristics['style']}

【推奨する{category.value}アイテム】
{products_text}

【{category.value}の役割】
{category_info['effect']}
{category_info['usage']}

以下のルールに従って、50-80文字で推奨理由を書いてください：

1. 小学5年生でもわかる簡単な言葉を使う
2. {personal_color_type.value.title()}タイプの特徴を活かす理由を説明する
3. なぜその色や素材が似合うのか具体的に説明する
4. ポジティブで励ましの言葉を入れる
5. 「です・ます調」で書く

例文：
「Springタイプのあなたには明るい色のトップスがぴったり！フレッシュで元気な印象になって、お肌も明るく見えますよ。」
"""

        return prompt.strip()

    @classmethod
    def get_fallback_explanation(
        cls, personal_color_type: PersonalColorType, category: ClothingCategory
    ) -> str:
        """フォールバック用の説明文を取得"""

        fallback_messages = {
            PersonalColorType.SPRING: {
                ClothingCategory.TOPS: "Springタイプのあなたには、明るく鮮やかな色合いのトップスがおすすめです。フレッシュで元気な印象を与えます。",
                ClothingCategory.BOTTOMS: "軽やかな素材感のボトムスで、春らしい明るい印象を演出しましょう。活動的な印象にぴったりです。",
                ClothingCategory.ACCESSORIES: "華やかなアクセサリーで、春らしい輝きをプラスしましょう。明るい色合いがあなたの魅力を引き立てます。",
            },
            PersonalColorType.SUMMER: {
                ClothingCategory.TOPS: "Summerタイプのあなたには、涼しげで上品な色合いのトップスが似合います。エレガントな印象を演出します。",
                ClothingCategory.BOTTOMS: "落ち着いた色合いのボトムスで、知的で上品な印象を作りましょう。洗練された大人の魅力が引き立ちます。",
                ClothingCategory.ACCESSORIES: "上品なアクセサリーで、クールで洗練された印象をプラスしましょう。シルバー系の色合いがおすすめです。",
            },
            PersonalColorType.AUTUMN: {
                ClothingCategory.TOPS: "Autumnタイプのあなたには、深みのある暖色系のトップスがおすすめです。リッチで温かみのある印象を演出します。",
                ClothingCategory.BOTTOMS: "アースカラーのボトムスで、大人っぽく上品な印象を作りましょう。深みのある色合いがあなたの魅力を引き立てます。",
                ClothingCategory.ACCESSORIES: "ゴールド系のアクセサリーで、温かみのある華やかさをプラスしましょう。リッチな印象を演出できます。",
            },
            PersonalColorType.WINTER: {
                ClothingCategory.TOPS: "Winterタイプのあなたには、クリアでシャープな色合いのトップスが似合います。洗練された印象を演出します。",
                ClothingCategory.BOTTOMS: "モノトーンやクールな色合いのボトムスで、スタイリッシュな印象を作りましょう。都会的な魅力が引き立ちます。",
                ClothingCategory.ACCESSORIES: "シルバーやプラチナ系のアクセサリーで、クールで洗練された印象をプラスしましょう。モダンな印象を演出できます。",
            },
        }

        return fallback_messages.get(personal_color_type, {}).get(
            category, "あなたに似合う素敵なファッションアイテムです。"
        )