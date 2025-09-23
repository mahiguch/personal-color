import pytest
from src.domain.enums import PersonalColorType, StylePreference, Season


class TestPersonalColorType:
    """PersonalColorType列挙型のテストクラス"""
    
    def test_all_color_types_exist(self):
        """全ての色タイプが定義されているかテスト"""
        expected_types = ["SPRING", "SUMMER", "AUTUMN", "WINTER"]
        
        for color_type in expected_types:
            assert hasattr(PersonalColorType, color_type)
            assert PersonalColorType[color_type].value == color_type
    
    def test_color_type_values(self):
        """色タイプの値が正しいかテスト"""
        assert PersonalColorType.SPRING.value == "SPRING"
        assert PersonalColorType.SUMMER.value == "SUMMER"
        assert PersonalColorType.AUTUMN.value == "AUTUMN"
        assert PersonalColorType.WINTER.value == "WINTER"


class TestStylePreference:
    """StylePreference列挙型のテストクラス"""
    
    def test_all_style_preferences_exist(self):
        """全てのスタイル選好が定義されているかテスト"""
        expected_styles = ["CASUAL", "FORMAL", "ELEGANT", "CUTE", "COOL"]
        
        for style in expected_styles:
            assert hasattr(StylePreference, style)
            assert StylePreference[style].value == style
    
    def test_style_preference_values(self):
        """スタイル選好の値が正しいかテスト"""
        assert StylePreference.CASUAL.value == "CASUAL"
        assert StylePreference.FORMAL.value == "FORMAL"
        assert StylePreference.ELEGANT.value == "ELEGANT"
        assert StylePreference.CUTE.value == "CUTE"
        assert StylePreference.COOL.value == "COOL"


class TestSeason:
    """Season列挙型のテストクラス"""
    
    def test_all_seasons_exist(self):
        """全ての季節が定義されているかテスト"""
        expected_seasons = ["SPRING", "SUMMER", "AUTUMN", "WINTER"]
        
        for season in expected_seasons:
            assert hasattr(Season, season)
            assert Season[season].value == season
    
    def test_season_values(self):
        """季節の値が正しいかテスト"""
        assert Season.SPRING.value == "SPRING"
        assert Season.SUMMER.value == "SUMMER"
        assert Season.AUTUMN.value == "AUTUMN"
        assert Season.WINTER.value == "WINTER"
