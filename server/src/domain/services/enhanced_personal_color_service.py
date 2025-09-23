"""
Enhanced Personal Color Service

パーソナルカラータイプに基づく詳細なカラーパレット、
季節対応、カラーハーモニー計算を提供する強化されたサービス
"""

from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import logging

from src.domain.enums import PersonalColorType, Season


logger = logging.getLogger(__name__)


class ColorHarmonyType(Enum):
    """カラーハーモニータイプ"""
    MONOCHROMATIC = "monochromatic"      # 単色調和
    ANALOGOUS = "analogous"              # 類似色調和
    COMPLEMENTARY = "complementary"      # 補色調和
    TRIADIC = "triadic"                  # 三角色調和
    SPLIT_COMPLEMENTARY = "split_complementary"  # 分裂補色調和
    TETRADIC = "tetradic"               # 四角色調和


class ColorIntensity(Enum):
    """色の強度"""
    SOFT = "soft"        # ソフト
    MEDIUM = "medium"    # ミディアム
    VIVID = "vivid"      # ビビッド
    DEEP = "deep"        # ディープ
    LIGHT = "light"      # ライト
    DARK = "dark"        # ダーク


@dataclass
class ColorInfo:
    """色情報の詳細データクラス"""
    name: str                    # 色名
    hex_code: str               # HEXコード
    rgb: Tuple[int, int, int]   # RGB値
    hsl: Tuple[int, int, int]   # HSL値
    intensity: ColorIntensity   # 色の強度
    season_score: float         # 季節適合度スコア (0.0-1.0)
    description: str            # 色の説明


@dataclass
class ColorPalette:
    """カラーパレット"""
    personal_color_type: PersonalColorType
    season: Season
    primary_colors: List[ColorInfo]      # 主要色
    secondary_colors: List[ColorInfo]    # 副次色
    accent_colors: List[ColorInfo]       # アクセント色
    neutral_colors: List[ColorInfo]      # ニュートラル色
    avoid_colors: List[ColorInfo]        # 避けるべき色


@dataclass
class ColorHarmony:
    """カラーハーモニー結果"""
    harmony_type: ColorHarmonyType
    base_color: ColorInfo
    harmony_colors: List[ColorInfo]
    harmony_score: float                 # 調和度スコア (0.0-1.0)
    description: str                     # ハーモニーの説明
    styling_advice: str                  # スタイリングアドバイス


@dataclass
class PersonalColorAnalysis:
    """パーソナルカラー分析結果"""
    personal_color_type: PersonalColorType
    season: Season
    color_palette: ColorPalette
    recommended_harmonies: List[ColorHarmony]
    color_strengths: List[str]           # 色の強み
    styling_tips: List[str]              # スタイリングのコツ
    seasonal_recommendations: Dict[Season, List[str]]  # 季節別推薦


class EnhancedPersonalColorService:
    """強化されたパーソナルカラーサービス"""
    
    def __init__(self):
        """サービスの初期化"""
        self.color_palettes = self._initialize_color_palettes()
        self.harmony_rules = self._initialize_harmony_rules()
        self.seasonal_adjustments = self._initialize_seasonal_adjustments()
    
    def get_personal_color_analysis(
        self,
        personal_color_type: PersonalColorType,
        season: Season = Season.SPRING
    ) -> PersonalColorAnalysis:
        """
        パーソナルカラーの詳細分析を取得
        
        Args:
            personal_color_type: パーソナルカラータイプ
            season: 季節
            
        Returns:
            パーソナルカラー分析結果
        """
        logger.info(f"Getting personal color analysis: {personal_color_type.value}, {season.value}")
        
        # カラーパレットの取得
        color_palette = self._get_color_palette(personal_color_type, season)
        
        # ハーモニー推薦の生成
        recommended_harmonies = self._generate_color_harmonies(color_palette)
        
        # 色の強みとスタイリングのコツを取得
        color_strengths = self._get_color_strengths(personal_color_type)
        styling_tips = self._get_styling_tips(personal_color_type, season)
        
        # 季節別推薦の生成
        seasonal_recommendations = self._get_seasonal_recommendations(personal_color_type)
        
        return PersonalColorAnalysis(
            personal_color_type=personal_color_type,
            season=season,
            color_palette=color_palette,
            recommended_harmonies=recommended_harmonies,
            color_strengths=color_strengths,
            styling_tips=styling_tips,
            seasonal_recommendations=seasonal_recommendations
        )
    
    def calculate_color_harmony(
        self,
        base_color: ColorInfo,
        harmony_type: ColorHarmonyType,
        personal_color_type: PersonalColorType
    ) -> ColorHarmony:
        """
        カラーハーモニーを計算
        
        Args:
            base_color: ベースとなる色
            harmony_type: ハーモニータイプ
            personal_color_type: パーソナルカラータイプ
            
        Returns:
            カラーハーモニー結果
        """
        logger.info(f"Calculating color harmony: {harmony_type.value}")
        
        # ハーモニー色の計算
        harmony_colors = self._calculate_harmony_colors(base_color, harmony_type)
        
        # パーソナルカラーとの適合性チェック
        filtered_colors = self._filter_colors_by_personal_type(harmony_colors, personal_color_type)
        
        # ハーモニースコアの計算
        harmony_score = self._calculate_harmony_score(base_color, filtered_colors, personal_color_type)
        
        # 説明とアドバイスの生成
        description = self._generate_harmony_description(harmony_type, harmony_score)
        styling_advice = self._generate_styling_advice(base_color, filtered_colors, personal_color_type)
        
        return ColorHarmony(
            harmony_type=harmony_type,
            base_color=base_color,
            harmony_colors=filtered_colors,
            harmony_score=harmony_score,
            description=description,
            styling_advice=styling_advice
        )
    
    def get_seasonal_color_recommendations(
        self,
        personal_color_type: PersonalColorType,
        target_season: Season
    ) -> List[ColorInfo]:
        """
        季節に応じた色推薦を取得
        
        Args:
            personal_color_type: パーソナルカラータイプ
            target_season: 対象季節
            
        Returns:
            推薦色のリスト
        """
        base_palette = self._get_color_palette(personal_color_type, target_season)
        seasonal_adjustment = self.seasonal_adjustments.get(target_season, {})
        
        # 季節調整を適用
        adjusted_colors = []
        for color in base_palette.primary_colors + base_palette.secondary_colors:
            adjusted_color = self._apply_seasonal_adjustment(color, seasonal_adjustment)
            adjusted_colors.append(adjusted_color)
        
        # 季節スコアでソート
        adjusted_colors.sort(key=lambda c: c.season_score, reverse=True)
        
        return adjusted_colors[:10]  # 上位10色を返す
    
    def _initialize_color_palettes(self) -> Dict[PersonalColorType, Dict[Season, ColorPalette]]:
        """カラーパレットの初期化"""
        palettes = {}
        
        # Spring タイプのパレット
        palettes[PersonalColorType.SPRING] = {
            Season.SPRING: self._create_spring_palette(PersonalColorType.SPRING, Season.SPRING),
            Season.SUMMER: self._create_spring_palette(PersonalColorType.SPRING, Season.SUMMER),
            Season.AUTUMN: self._create_spring_palette(PersonalColorType.SPRING, Season.AUTUMN),
            Season.WINTER: self._create_spring_palette(PersonalColorType.SPRING, Season.WINTER),
        }
        
        # Summer タイプのパレット
        palettes[PersonalColorType.SUMMER] = {
            Season.SPRING: self._create_summer_palette(PersonalColorType.SUMMER, Season.SPRING),
            Season.SUMMER: self._create_summer_palette(PersonalColorType.SUMMER, Season.SUMMER),
            Season.AUTUMN: self._create_summer_palette(PersonalColorType.SUMMER, Season.AUTUMN),
            Season.WINTER: self._create_summer_palette(PersonalColorType.SUMMER, Season.WINTER),
        }
        
        # Autumn タイプのパレット
        palettes[PersonalColorType.AUTUMN] = {
            Season.SPRING: self._create_autumn_palette(PersonalColorType.AUTUMN, Season.SPRING),
            Season.SUMMER: self._create_autumn_palette(PersonalColorType.AUTUMN, Season.SUMMER),
            Season.AUTUMN: self._create_autumn_palette(PersonalColorType.AUTUMN, Season.AUTUMN),
            Season.WINTER: self._create_autumn_palette(PersonalColorType.AUTUMN, Season.WINTER),
        }
        
        # Winter タイプのパレット
        palettes[PersonalColorType.WINTER] = {
            Season.SPRING: self._create_winter_palette(PersonalColorType.WINTER, Season.SPRING),
            Season.SUMMER: self._create_winter_palette(PersonalColorType.WINTER, Season.SUMMER),
            Season.AUTUMN: self._create_winter_palette(PersonalColorType.WINTER, Season.AUTUMN),
            Season.WINTER: self._create_winter_palette(PersonalColorType.WINTER, Season.WINTER),
        }
        
        return palettes
    
    def _create_spring_palette(self, personal_color: PersonalColorType, season: Season) -> ColorPalette:
        """Spring タイプのカラーパレット作成"""
        # 季節調整係数
        season_multiplier = self._get_season_multiplier(season)
        
        primary_colors = [
            ColorInfo("コーラルピンク", "#FF7F7F", (255, 127, 127), (0, 50, 75), ColorIntensity.MEDIUM, 0.9 * season_multiplier, "温かみのあるピンク"),
            ColorInfo("ピーチ", "#FFCBA4", (255, 203, 164), (25, 100, 82), ColorIntensity.SOFT, 0.95 * season_multiplier, "柔らかなピーチ色"),
            ColorInfo("ライトイエロー", "#FFFF99", (255, 255, 153), (60, 100, 80), ColorIntensity.LIGHT, 0.8 * season_multiplier, "明るい黄色"),
        ]
        
        secondary_colors = [
            ColorInfo("アクアブルー", "#7FDBFF", (127, 219, 255), (194, 100, 75), ColorIntensity.MEDIUM, 0.7 * season_multiplier, "爽やかな水色"),
            ColorInfo("ライトグリーン", "#2ECC40", (46, 204, 64), (127, 63, 49), ColorIntensity.VIVID, 0.85 * season_multiplier, "鮮やかな緑"),
        ]
        
        accent_colors = [
            ColorInfo("ホットピンク", "#FF69B4", (255, 105, 180), (330, 100, 71), ColorIntensity.VIVID, 0.6 * season_multiplier, "鮮やかなピンク"),
            ColorInfo("ターコイズ", "#40E0D0", (64, 224, 208), (174, 72, 56), ColorIntensity.VIVID, 0.7 * season_multiplier, "鮮やかなターコイズ"),
        ]
        
        neutral_colors = [
            ColorInfo("アイボリー", "#FFFFF0", (255, 255, 240), (60, 100, 97), ColorIntensity.LIGHT, 0.95 * season_multiplier, "温かな白"),
            ColorInfo("ライトベージュ", "#F5F5DC", (245, 245, 220), (60, 56, 91), ColorIntensity.LIGHT, 0.9 * season_multiplier, "優しいベージュ"),
        ]
        
        avoid_colors = [
            ColorInfo("ブラック", "#000000", (0, 0, 0), (0, 0, 0), ColorIntensity.DARK, 0.1, "重すぎる黒"),
            ColorInfo("ダークネイビー", "#000080", (0, 0, 128), (240, 100, 25), ColorIntensity.DARK, 0.2, "重いネイビー"),
        ]
        
        return ColorPalette(
            personal_color_type=personal_color,
            season=season,
            primary_colors=primary_colors,
            secondary_colors=secondary_colors,
            accent_colors=accent_colors,
            neutral_colors=neutral_colors,
            avoid_colors=avoid_colors
        )
    
    def _create_summer_palette(self, personal_color: PersonalColorType, season: Season) -> ColorPalette:
        """Summer タイプのカラーパレット作成"""
        season_multiplier = self._get_season_multiplier(season)
        
        primary_colors = [
            ColorInfo("ラベンダー", "#E6E6FA", (230, 230, 250), (240, 67, 94), ColorIntensity.SOFT, 0.95 * season_multiplier, "上品な薄紫"),
            ColorInfo("パウダーブルー", "#B0E0E6", (176, 224, 230), (187, 52, 80), ColorIntensity.SOFT, 0.9 * season_multiplier, "優しい水色"),
            ColorInfo("ローズピンク", "#FFB6C1", (255, 182, 193), (351, 100, 86), ColorIntensity.SOFT, 0.85 * season_multiplier, "柔らかなローズ"),
        ]
        
        secondary_colors = [
            ColorInfo("ミントグリーン", "#98FB98", (152, 251, 152), (120, 93, 79), ColorIntensity.SOFT, 0.8 * season_multiplier, "爽やかなミント"),
            ColorInfo("ライラック", "#DDA0DD", (221, 160, 221), (300, 47, 75), ColorIntensity.MEDIUM, 0.75 * season_multiplier, "優雅な薄紫"),
        ]
        
        accent_colors = [
            ColorInfo("ソフトピンク", "#FFC0CB", (255, 192, 203), (350, 100, 88), ColorIntensity.SOFT, 0.8 * season_multiplier, "柔らかなピンク"),
            ColorInfo("スカイブルー", "#87CEEB", (135, 206, 235), (197, 71, 73), ColorIntensity.MEDIUM, 0.85 * season_multiplier, "空のような青"),
        ]
        
        neutral_colors = [
            ColorInfo("パールホワイト", "#F8F8FF", (248, 248, 255), (240, 100, 99), ColorIntensity.LIGHT, 0.95 * season_multiplier, "真珠のような白"),
            ColorInfo("ライトグレー", "#D3D3D3", (211, 211, 211), (0, 0, 83), ColorIntensity.LIGHT, 0.9 * season_multiplier, "上品なグレー"),
        ]
        
        avoid_colors = [
            ColorInfo("オレンジ", "#FFA500", (255, 165, 0), (39, 100, 50), ColorIntensity.VIVID, 0.2, "強すぎるオレンジ"),
            ColorInfo("ブライトイエロー", "#FFFF00", (255, 255, 0), (60, 100, 50), ColorIntensity.VIVID, 0.1, "鮮やかすぎる黄色"),
        ]
        
        return ColorPalette(
            personal_color_type=personal_color,
            season=season,
            primary_colors=primary_colors,
            secondary_colors=secondary_colors,
            accent_colors=accent_colors,
            neutral_colors=neutral_colors,
            avoid_colors=avoid_colors
        )
    
    def _create_autumn_palette(self, personal_color: PersonalColorType, season: Season) -> ColorPalette:
        """Autumn タイプのカラーパレット作成"""
        season_multiplier = self._get_season_multiplier(season)
        
        primary_colors = [
            ColorInfo("バーントオレンジ", "#CC5500", (204, 85, 0), (25, 100, 40), ColorIntensity.DEEP, 0.95 * season_multiplier, "深いオレンジ"),
            ColorInfo("オリーブグリーン", "#808000", (128, 128, 0), (60, 100, 25), ColorIntensity.DEEP, 0.9 * season_multiplier, "落ち着いた緑"),
            ColorInfo("ダークゴールド", "#B8860B", (184, 134, 11), (43, 89, 38), ColorIntensity.DEEP, 0.85 * season_multiplier, "深いゴールド"),
        ]
        
        secondary_colors = [
            ColorInfo("テラコッタ", "#E2725B", (226, 114, 91), (10, 70, 62), ColorIntensity.MEDIUM, 0.8 * season_multiplier, "土のような赤茶"),
            ColorInfo("フォレストグリーン", "#228B22", (34, 139, 34), (120, 61, 27), ColorIntensity.DEEP, 0.75 * season_multiplier, "森の深緑"),
        ]
        
        accent_colors = [
            ColorInfo("マスタード", "#FFDB58", (255, 219, 88), (47, 100, 67), ColorIntensity.MEDIUM, 0.7 * season_multiplier, "からしのような黄色"),
            ColorInfo("ラストレッド", "#B22222", (178, 34, 34), (0, 68, 42), ColorIntensity.DEEP, 0.65 * season_multiplier, "錆のような赤"),
        ]
        
        neutral_colors = [
            ColorInfo("クリーム", "#FFFDD0", (255, 253, 208), (59, 100, 91), ColorIntensity.LIGHT, 0.9 * season_multiplier, "温かなクリーム"),
            ColorInfo("カーキ", "#F0E68C", (240, 230, 140), (54, 77, 75), ColorIntensity.MEDIUM, 0.85 * season_multiplier, "自然なカーキ"),
        ]
        
        avoid_colors = [
            ColorInfo("ネオンピンク", "#FF1493", (255, 20, 147), (328, 100, 54), ColorIntensity.VIVID, 0.1, "派手すぎるピンク"),
            ColorInfo("アイスブルー", "#B0E0E6", (176, 224, 230), (187, 52, 80), ColorIntensity.SOFT, 0.2, "冷たすぎる青"),
        ]
        
        return ColorPalette(
            personal_color_type=personal_color,
            season=season,
            primary_colors=primary_colors,
            secondary_colors=secondary_colors,
            accent_colors=accent_colors,
            neutral_colors=neutral_colors,
            avoid_colors=avoid_colors
        )
    
    def _create_winter_palette(self, personal_color: PersonalColorType, season: Season) -> ColorPalette:
        """Winter タイプのカラーパレット作成"""
        season_multiplier = self._get_season_multiplier(season)
        
        primary_colors = [
            ColorInfo("ピュアブラック", "#000000", (0, 0, 0), (0, 0, 0), ColorIntensity.DARK, 0.95 * season_multiplier, "純粋な黒"),
            ColorInfo("ロイヤルブルー", "#4169E1", (65, 105, 225), (225, 73, 57), ColorIntensity.VIVID, 0.9 * season_multiplier, "王室の青"),
            ColorInfo("エメラルドグリーン", "#50C878", (80, 200, 120), (140, 60, 55), ColorIntensity.VIVID, 0.85 * season_multiplier, "エメラルドの緑"),
        ]
        
        secondary_colors = [
            ColorInfo("フューシャ", "#FF00FF", (255, 0, 255), (300, 100, 50), ColorIntensity.VIVID, 0.8 * season_multiplier, "鮮烈なピンク"),
            ColorInfo("レモンイエロー", "#FFFF00", (255, 255, 0), (60, 100, 50), ColorIntensity.VIVID, 0.75 * season_multiplier, "純粋な黄色"),
        ]
        
        accent_colors = [
            ColorInfo("クリムゾン", "#DC143C", (220, 20, 60), (348, 83, 47), ColorIntensity.VIVID, 0.7 * season_multiplier, "深紅"),
            ColorInfo("コバルトブルー", "#0047AB", (0, 71, 171), (215, 100, 34), ColorIntensity.VIVID, 0.75 * season_multiplier, "鮮やかな青"),
        ]
        
        neutral_colors = [
            ColorInfo("ピュアホワイト", "#FFFFFF", (255, 255, 255), (0, 0, 100), ColorIntensity.LIGHT, 0.95 * season_multiplier, "純粋な白"),
            ColorInfo("チャコールグレー", "#36454F", (54, 69, 79), (198, 32, 26), ColorIntensity.DARK, 0.9 * season_multiplier, "炭のようなグレー"),
        ]
        
        avoid_colors = [
            ColorInfo("ベージュ", "#F5F5DC", (245, 245, 220), (60, 56, 91), ColorIntensity.LIGHT, 0.2, "ぼんやりしたベージュ"),
            ColorInfo("サーモンピンク", "#FA8072", (250, 128, 114), (6, 93, 71), ColorIntensity.MEDIUM, 0.1, "濁ったピンク"),
        ]
        
        return ColorPalette(
            personal_color_type=personal_color,
            season=season,
            primary_colors=primary_colors,
            secondary_colors=secondary_colors,
            accent_colors=accent_colors,
            neutral_colors=neutral_colors,
            avoid_colors=avoid_colors
        )
    
    def _get_season_multiplier(self, season: Season) -> float:
        """季節による調整係数を取得"""
        return {
            Season.SPRING: 1.0,
            Season.SUMMER: 0.9,
            Season.AUTUMN: 0.8,
            Season.WINTER: 0.7
        }.get(season, 1.0)
    
    def _get_color_palette(self, personal_color_type: PersonalColorType, season: Season) -> ColorPalette:
        """指定されたパーソナルカラーと季節のパレットを取得"""
        return self.color_palettes[personal_color_type][season]
    
    def _initialize_harmony_rules(self) -> Dict[ColorHarmonyType, Dict]:
        """ハーモニールールの初期化"""
        return {
            ColorHarmonyType.MONOCHROMATIC: {
                "angle_range": [0, 30],
                "saturation_variance": 0.3,
                "brightness_variance": 0.4
            },
            ColorHarmonyType.ANALOGOUS: {
                "angle_range": [30, 90],
                "saturation_variance": 0.2,
                "brightness_variance": 0.3
            },
            ColorHarmonyType.COMPLEMENTARY: {
                "angle_range": [150, 210],
                "saturation_variance": 0.1,
                "brightness_variance": 0.2
            },
            ColorHarmonyType.TRIADIC: {
                "angle_range": [120, 120],
                "saturation_variance": 0.2,
                "brightness_variance": 0.3
            }
        }
    
    def _initialize_seasonal_adjustments(self) -> Dict[Season, Dict]:
        """季節調整の初期化"""
        return {
            Season.SPRING: {
                "brightness_boost": 0.1,
                "saturation_boost": 0.05,
                "warm_shift": 0.05
            },
            Season.SUMMER: {
                "brightness_boost": 0.0,
                "saturation_reduction": 0.1,
                "cool_shift": 0.05
            },
            Season.AUTUMN: {
                "brightness_reduction": 0.05,
                "saturation_boost": 0.1,
                "warm_shift": 0.1
            },
            Season.WINTER: {
                "contrast_boost": 0.15,
                "saturation_boost": 0.05,
                "cool_shift": 0.1
            }
        }
    
    def _generate_color_harmonies(self, color_palette: ColorPalette) -> List[ColorHarmony]:
        """カラーハーモニーの生成"""
        harmonies = []
        
        # 主要色からハーモニーを生成
        for primary_color in color_palette.primary_colors[:2]:  # 上位2色
            for harmony_type in [ColorHarmonyType.ANALOGOUS, ColorHarmonyType.COMPLEMENTARY]:
                harmony = self.calculate_color_harmony(
                    base_color=primary_color,
                    harmony_type=harmony_type,
                    personal_color_type=color_palette.personal_color_type
                )
                harmonies.append(harmony)
        
        # スコア順でソート
        harmonies.sort(key=lambda h: h.harmony_score, reverse=True)
        return harmonies[:4]  # 上位4つを返す
    
    def _calculate_harmony_colors(self, base_color: ColorInfo, harmony_type: ColorHarmonyType) -> List[ColorInfo]:
        """ハーモニー色の計算（簡略化実装）"""
        # 実際の実装では色相環での計算を行う
        # ここではモック実装
        return [
            ColorInfo(f"Harmony Color 1", "#FF9999", (255, 153, 153), (0, 40, 80), ColorIntensity.MEDIUM, 0.8, "ハーモニー色1"),
            ColorInfo(f"Harmony Color 2", "#99FF99", (153, 255, 153), (120, 40, 80), ColorIntensity.MEDIUM, 0.8, "ハーモニー色2"),
        ]
    
    def _filter_colors_by_personal_type(self, colors: List[ColorInfo], personal_color_type: PersonalColorType) -> List[ColorInfo]:
        """パーソナルカラータイプでフィルタリング"""
        # 実際の実装では色の特性を分析
        return colors  # 簡略化
    
    def _calculate_harmony_score(self, base_color: ColorInfo, harmony_colors: List[ColorInfo], personal_color_type: PersonalColorType) -> float:
        """ハーモニースコアの計算"""
        # 実際の実装では色理論に基づく計算
        return 0.85  # 簡略化
    
    def _generate_harmony_description(self, harmony_type: ColorHarmonyType, harmony_score: float) -> str:
        """ハーモニーの説明生成"""
        descriptions = {
            ColorHarmonyType.ANALOGOUS: "類似色による穏やかで調和のとれた組み合わせ",
            ColorHarmonyType.COMPLEMENTARY: "補色による鮮やかで印象的な組み合わせ",
            ColorHarmonyType.MONOCHROMATIC: "同色系による洗練された組み合わせ",
            ColorHarmonyType.TRIADIC: "三角配色による バランスの良い組み合わせ"
        }
        base_description = descriptions.get(harmony_type, "調和のとれた色の組み合わせ")
        confidence = "高い" if harmony_score > 0.8 else "良い" if harmony_score > 0.6 else "適度な"
        return f"{base_description}。{confidence}調和度です。"
    
    def _generate_styling_advice(self, base_color: ColorInfo, harmony_colors: List[ColorInfo], personal_color_type: PersonalColorType) -> str:
        """スタイリングアドバイスの生成"""
        advice_templates = {
            PersonalColorType.SPRING: "明るく活動的な印象を与える組み合わせです。カジュアルからビジネスまで幅広く活用できます。",
            PersonalColorType.SUMMER: "上品で洗練された印象を与える組み合わせです。エレガントなスタイルに最適です。",
            PersonalColorType.AUTUMN: "温かみがあり落ち着いた印象を与える組み合わせです。ナチュラルなスタイルにぴったりです。",
            PersonalColorType.WINTER: "シャープで印象的な組み合わせです。フォーマルやモダンなスタイルに効果的です。"
        }
        return advice_templates.get(personal_color_type, "バランスの良い色の組み合わせです。")
    
    def _get_color_strengths(self, personal_color_type: PersonalColorType) -> List[str]:
        """色の強みを取得"""
        strengths = {
            PersonalColorType.SPRING: ["明るく活動的な印象", "若々しい魅力", "親しみやすさ", "エネルギッシュな雰囲気"],
            PersonalColorType.SUMMER: ["上品で洗練された印象", "優雅さ", "知的な魅力", "穏やかな雰囲気"],
            PersonalColorType.AUTUMN: ["温かみのある印象", "落ち着いた魅力", "自然な美しさ", "安定感"],
            PersonalColorType.WINTER: ["シャープで印象的", "クールな魅力", "モダンな印象", "存在感"]
        }
        return strengths.get(personal_color_type, ["調和のとれた印象"])
    
    def _get_styling_tips(self, personal_color_type: PersonalColorType, season: Season) -> List[str]:
        """スタイリングのコツを取得"""
        base_tips = {
            PersonalColorType.SPRING: [
                "明るい色をメインに使用",
                "コントラストを効かせる",
                "アクセサリーでポイントを作る"
            ],
            PersonalColorType.SUMMER: [
                "ソフトな色調でまとめる",
                "上品なアクセサリーを選ぶ",
                "シルエットを重視する"
            ],
            PersonalColorType.AUTUMN: [
                "アースカラーを基調に",
                "自然素材を取り入れる",
                "レイヤードを活用する"
            ],
            PersonalColorType.WINTER: [
                "はっきりした色を選ぶ",
                "シンプルで洗練されたデザイン",
                "モノトーンを効果的に使う"
            ]
        }
        
        seasonal_tips = {
            Season.SPRING: ["軽やかな素材を選ぶ", "パステルカラーを取り入れる"],
            Season.SUMMER: ["涼しげな色合いを重視", "リネンなど通気性の良い素材"],
            Season.AUTUMN: ["深みのある色を選ぶ", "重厚感のある素材を活用"],
            Season.WINTER: ["コントラストを強調", "構造的なデザインを選ぶ"]
        }
        
        return base_tips.get(personal_color_type, []) + seasonal_tips.get(season, [])
    
    def _get_seasonal_recommendations(self, personal_color_type: PersonalColorType) -> Dict[Season, List[str]]:
        """季節別推薦を取得"""
        return {
            Season.SPRING: [f"{personal_color_type.value}に春らしい明るい色合いを", "パステルカラーを取り入れて"],
            Season.SUMMER: [f"{personal_color_type.value}に涼しげな色調を", "ソフトな色合いでまとめて"],
            Season.AUTUMN: [f"{personal_color_type.value}に深みのある色を", "アースカラーを基調に"],
            Season.WINTER: [f"{personal_color_type.value}にシャープな色合いを", "コントラストを効かせて"]
        }
    
    def _apply_seasonal_adjustment(self, color: ColorInfo, adjustment: Dict) -> ColorInfo:
        """季節調整を適用"""
        # 実際の実装では色のHSL値を調整
        # ここでは季節スコアのみ調整
        adjusted_color = color
        if "brightness_boost" in adjustment:
            adjusted_color.season_score = min(1.0, color.season_score + adjustment["brightness_boost"])
        elif "brightness_reduction" in adjustment:
            adjusted_color.season_score = max(0.0, color.season_score - adjustment["brightness_reduction"])
        
        return adjusted_color


# ファクトリー関数
def create_enhanced_personal_color_service() -> EnhancedPersonalColorService:
    """Enhanced Personal Color Service のファクトリー関数"""
    return EnhancedPersonalColorService()
