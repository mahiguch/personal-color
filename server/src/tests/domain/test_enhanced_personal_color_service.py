"""
Enhanced Personal Color Service のテストクラス
"""

import pytest
from src.domain.services.enhanced_personal_color_service import (
    EnhancedPersonalColorService,
    ColorHarmonyType,
    ColorIntensity,
    ColorInfo,
    ColorPalette,
    ColorHarmony,
    PersonalColorAnalysis,
    create_enhanced_personal_color_service
)
from src.domain.enums import PersonalColorType, Season


class TestEnhancedPersonalColorService:
    """Enhanced Personal Color Service のテストクラス"""
    
    @pytest.fixture
    def color_service(self):
        """Personal Color Service のインスタンス"""
        return create_enhanced_personal_color_service()
    
    @pytest.fixture
    def sample_color_info(self):
        """サンプル色情報"""
        return ColorInfo(
            name="サンプルレッド",
            hex_code="#FF0000",
            rgb=(255, 0, 0),
            hsl=(0, 100, 50),
            intensity=ColorIntensity.VIVID,
            season_score=0.8,
            description="鮮やかな赤"
        )
    
    def test_service_initialization(self, color_service):
        """サービスの初期化テスト"""
        assert color_service is not None
        assert hasattr(color_service, 'color_palettes')
        assert hasattr(color_service, 'harmony_rules')
        assert hasattr(color_service, 'seasonal_adjustments')
        
        # すべてのパーソナルカラータイプが初期化されているかチェック
        for personal_color_type in PersonalColorType:
            assert personal_color_type in color_service.color_palettes
            
            # すべての季節が定義されているかチェック
            for season in Season:
                assert season in color_service.color_palettes[personal_color_type]
    
    def test_get_personal_color_analysis_spring(self, color_service):
        """Spring タイプの分析テスト"""
        analysis = color_service.get_personal_color_analysis(
            PersonalColorType.SPRING,
            Season.SPRING
        )
        
        assert isinstance(analysis, PersonalColorAnalysis)
        assert analysis.personal_color_type == PersonalColorType.SPRING
        assert analysis.season == Season.SPRING
        assert len(analysis.color_strengths) > 0
        assert len(analysis.styling_tips) > 0
        assert len(analysis.recommended_harmonies) > 0
        
        # パレットの基本構造確認
        palette = analysis.color_palette
        assert len(palette.primary_colors) > 0
        assert len(palette.secondary_colors) > 0
        assert len(palette.accent_colors) > 0
        assert len(palette.neutral_colors) > 0
        assert len(palette.avoid_colors) > 0
    
    def test_get_personal_color_analysis_summer(self, color_service):
        """Summer タイプの分析テスト"""
        analysis = color_service.get_personal_color_analysis(
            PersonalColorType.SUMMER,
            Season.SUMMER
        )
        
        assert analysis.personal_color_type == PersonalColorType.SUMMER
        assert analysis.season == Season.SUMMER
        
        # Summer特有の色の特徴確認
        palette = analysis.color_palette
        primary_color = palette.primary_colors[0]
        assert primary_color.intensity in [ColorIntensity.SOFT, ColorIntensity.MEDIUM]
    
    def test_get_personal_color_analysis_autumn(self, color_service):
        """Autumn タイプの分析テスト"""
        analysis = color_service.get_personal_color_analysis(
            PersonalColorType.AUTUMN,
            Season.AUTUMN
        )
        
        assert analysis.personal_color_type == PersonalColorType.AUTUMN
        assert analysis.season == Season.AUTUMN
        
        # Autumn特有の色の特徴確認
        palette = analysis.color_palette
        primary_colors = palette.primary_colors
        assert any("オレンジ" in color.name or "グリーン" in color.name for color in primary_colors)
    
    def test_get_personal_color_analysis_winter(self, color_service):
        """Winter タイプの分析テスト"""
        analysis = color_service.get_personal_color_analysis(
            PersonalColorType.WINTER,
            Season.WINTER
        )
        
        assert analysis.personal_color_type == PersonalColorType.WINTER
        assert analysis.season == Season.WINTER
        
        # Winter特有の色の特徴確認
        palette = analysis.color_palette
        primary_colors = palette.primary_colors
        assert any(color.intensity == ColorIntensity.VIVID for color in primary_colors)
    
    def test_calculate_color_harmony_analogous(self, color_service, sample_color_info):
        """類似色ハーモニーの計算テスト"""
        harmony = color_service.calculate_color_harmony(
            base_color=sample_color_info,
            harmony_type=ColorHarmonyType.ANALOGOUS,
            personal_color_type=PersonalColorType.SPRING
        )
        
        assert isinstance(harmony, ColorHarmony)
        assert harmony.harmony_type == ColorHarmonyType.ANALOGOUS
        assert harmony.base_color == sample_color_info
        assert len(harmony.harmony_colors) > 0
        assert 0.0 <= harmony.harmony_score <= 1.0
        assert len(harmony.description) > 0
        assert len(harmony.styling_advice) > 0
    
    def test_calculate_color_harmony_complementary(self, color_service, sample_color_info):
        """補色ハーモニーの計算テスト"""
        harmony = color_service.calculate_color_harmony(
            base_color=sample_color_info,
            harmony_type=ColorHarmonyType.COMPLEMENTARY,
            personal_color_type=PersonalColorType.WINTER
        )
        
        assert harmony.harmony_type == ColorHarmonyType.COMPLEMENTARY
        assert "補色" in harmony.description
    
    def test_get_seasonal_color_recommendations(self, color_service):
        """季節色推薦のテスト"""
        recommendations = color_service.get_seasonal_color_recommendations(
            PersonalColorType.SPRING,
            Season.SPRING
        )
        
        assert isinstance(recommendations, list)
        assert len(recommendations) > 0
        assert len(recommendations) <= 10  # 最大10色
        
        # 色情報の構造確認
        for color in recommendations:
            assert isinstance(color, ColorInfo)
            assert hasattr(color, 'season_score')
            assert 0.0 <= color.season_score <= 1.0
        
        # スコア順になっているかチェック
        scores = [color.season_score for color in recommendations]
        assert scores == sorted(scores, reverse=True)
    
    def test_color_palette_structure(self, color_service):
        """カラーパレット構造のテスト"""
        for personal_color_type in PersonalColorType:
            for season in Season:
                palette = color_service._get_color_palette(personal_color_type, season)
                
                assert isinstance(palette, ColorPalette)
                assert palette.personal_color_type == personal_color_type
                assert palette.season == season
                
                # 各色リストの構造確認
                for color_list in [palette.primary_colors, palette.secondary_colors, 
                                 palette.accent_colors, palette.neutral_colors, palette.avoid_colors]:
                    assert isinstance(color_list, list)
                    for color in color_list:
                        assert isinstance(color, ColorInfo)
                        assert len(color.name) > 0
                        assert color.hex_code.startswith('#')
                        assert len(color.rgb) == 3
                        assert len(color.hsl) == 3
                        assert isinstance(color.intensity, ColorIntensity)
                        assert 0.0 <= color.season_score <= 1.0
    
    def test_season_multiplier(self, color_service):
        """季節調整係数のテスト"""
        multipliers = {}
        for season in Season:
            multiplier = color_service._get_season_multiplier(season)
            multipliers[season] = multiplier
            assert 0.0 < multiplier <= 1.0
        
        # Spring が基準（1.0）であることを確認
        assert multipliers[Season.SPRING] == 1.0
    
    def test_harmony_rules_initialization(self, color_service):
        """ハーモニールール初期化のテスト"""
        harmony_rules = color_service.harmony_rules
        
        for harmony_type in ColorHarmonyType:
            if harmony_type in harmony_rules:
                rule = harmony_rules[harmony_type]
                assert 'angle_range' in rule
                assert 'saturation_variance' in rule
                assert 'brightness_variance' in rule
                
                assert len(rule['angle_range']) == 2
                assert 0.0 <= rule['saturation_variance'] <= 1.0
                assert 0.0 <= rule['brightness_variance'] <= 1.0
    
    def test_seasonal_adjustments_initialization(self, color_service):
        """季節調整初期化のテスト"""
        seasonal_adjustments = color_service.seasonal_adjustments
        
        for season in Season:
            adjustment = seasonal_adjustments[season]
            assert isinstance(adjustment, dict)
            
            # 調整値が適切な範囲内であることを確認
            for key, value in adjustment.items():
                assert isinstance(value, (int, float))
                assert -1.0 <= value <= 1.0
    
    def test_color_strengths(self, color_service):
        """色の強み取得のテスト"""
        for personal_color_type in PersonalColorType:
            strengths = color_service._get_color_strengths(personal_color_type)
            
            assert isinstance(strengths, list)
            assert len(strengths) > 0
            
            for strength in strengths:
                assert isinstance(strength, str)
                assert len(strength) > 0
    
    def test_styling_tips(self, color_service):
        """スタイリングのコツ取得のテスト"""
        for personal_color_type in PersonalColorType:
            for season in Season:
                tips = color_service._get_styling_tips(personal_color_type, season)
                
                assert isinstance(tips, list)
                assert len(tips) > 0
                
                for tip in tips:
                    assert isinstance(tip, str)
                    assert len(tip) > 0
    
    def test_seasonal_recommendations(self, color_service):
        """季節別推薦取得のテスト"""
        for personal_color_type in PersonalColorType:
            recommendations = color_service._get_seasonal_recommendations(personal_color_type)
            
            assert isinstance(recommendations, dict)
            
            for season in Season:
                assert season in recommendations
                season_recs = recommendations[season]
                assert isinstance(season_recs, list)
                assert len(season_recs) > 0
                
                for rec in season_recs:
                    assert isinstance(rec, str)
                    assert len(rec) > 0
    
    def test_color_info_creation(self):
        """ColorInfo の作成テスト"""
        color = ColorInfo(
            name="テストレッド",
            hex_code="#FF0000",
            rgb=(255, 0, 0),
            hsl=(0, 100, 50),
            intensity=ColorIntensity.VIVID,
            season_score=0.9,
            description="テスト用の赤い色"
        )
        
        assert color.name == "テストレッド"
        assert color.hex_code == "#FF0000"
        assert color.rgb == (255, 0, 0)
        assert color.hsl == (0, 100, 50)
        assert color.intensity == ColorIntensity.VIVID
        assert color.season_score == 0.9
        assert color.description == "テスト用の赤い色"
    
    def test_color_harmony_creation(self, sample_color_info):
        """ColorHarmony の作成テスト"""
        harmony_colors = [
            ColorInfo("ハーモニー1", "#00FF00", (0, 255, 0), (120, 100, 50), ColorIntensity.VIVID, 0.8, "緑"),
            ColorInfo("ハーモニー2", "#0000FF", (0, 0, 255), (240, 100, 50), ColorIntensity.VIVID, 0.8, "青")
        ]
        
        harmony = ColorHarmony(
            harmony_type=ColorHarmonyType.TRIADIC,
            base_color=sample_color_info,
            harmony_colors=harmony_colors,
            harmony_score=0.85,
            description="三角配色の調和",
            styling_advice="バランスの良い配色です"
        )
        
        assert harmony.harmony_type == ColorHarmonyType.TRIADIC
        assert harmony.base_color == sample_color_info
        assert len(harmony.harmony_colors) == 2
        assert harmony.harmony_score == 0.85
        assert "三角配色" in harmony.description
        assert "バランス" in harmony.styling_advice
    
    def test_personal_color_analysis_creation(self, color_service):
        """PersonalColorAnalysis の作成テスト"""
        analysis = color_service.get_personal_color_analysis(
            PersonalColorType.SPRING,
            Season.SPRING
        )
        
        # 分析結果の完全性確認
        assert analysis.personal_color_type == PersonalColorType.SPRING
        assert analysis.season == Season.SPRING
        assert isinstance(analysis.color_palette, ColorPalette)
        assert isinstance(analysis.recommended_harmonies, list)
        assert isinstance(analysis.color_strengths, list)
        assert isinstance(analysis.styling_tips, list)
        assert isinstance(analysis.seasonal_recommendations, dict)
        
        # 各要素に内容があることを確認
        assert len(analysis.recommended_harmonies) > 0
        assert len(analysis.color_strengths) > 0
        assert len(analysis.styling_tips) > 0
        assert len(analysis.seasonal_recommendations) == len(Season)
    
    def test_factory_function(self):
        """ファクトリー関数のテスト"""
        service = create_enhanced_personal_color_service()
        
        assert isinstance(service, EnhancedPersonalColorService)
        assert hasattr(service, 'color_palettes')
        assert hasattr(service, 'harmony_rules')
        assert hasattr(service, 'seasonal_adjustments')
    
    def test_color_intensity_enum(self):
        """ColorIntensity 列挙型のテスト"""
        intensities = list(ColorIntensity)
        
        expected_intensities = [
            ColorIntensity.SOFT,
            ColorIntensity.MEDIUM,
            ColorIntensity.VIVID,
            ColorIntensity.DEEP,
            ColorIntensity.LIGHT,
            ColorIntensity.DARK
        ]
        
        for intensity in expected_intensities:
            assert intensity in intensities
            assert isinstance(intensity.value, str)
    
    def test_color_harmony_type_enum(self):
        """ColorHarmonyType 列挙型のテスト"""
        harmony_types = list(ColorHarmonyType)
        
        expected_types = [
            ColorHarmonyType.MONOCHROMATIC,
            ColorHarmonyType.ANALOGOUS,
            ColorHarmonyType.COMPLEMENTARY,
            ColorHarmonyType.TRIADIC,
            ColorHarmonyType.SPLIT_COMPLEMENTARY,
            ColorHarmonyType.TETRADIC
        ]
        
        for harmony_type in expected_types:
            assert harmony_type in harmony_types
            assert isinstance(harmony_type.value, str)
