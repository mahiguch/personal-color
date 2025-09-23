from enum import Enum


class PersonalColorType(Enum):
    """パーソナルカラータイプの列挙型"""
    SPRING = "spring"
    SUMMER = "summer"
    AUTUMN = "autumn"
    WINTER = "winter"


class StylePreference(Enum):
    """スタイル傾向の列挙型"""
    CASUAL = "casual"
    FORMAL = "formal"
    BUSINESS = "business"
    SPORTY = "sporty"
    ELEGANT = "elegant"
    CUTE = "cute"
    COOL = "cool"
    NATURAL = "natural"
    CLASSIC = "classic"
    FEMININE = "feminine"


class Season(Enum):
    """季節の列挙型"""
    SPRING = "spring"
    SUMMER = "summer"
    AUTUMN = "autumn"
    WINTER = "winter"
