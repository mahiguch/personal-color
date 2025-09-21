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
    SPORTY = "sporty"


class Season(Enum):
    """季節の列挙型"""
    SPRING = "spring"
    SUMMER = "summer"
    AUTUMN = "autumn"
    WINTER = "winter"
