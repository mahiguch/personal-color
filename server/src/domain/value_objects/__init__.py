from dataclasses import dataclass
from typing import List


@dataclass(frozen=True)
class ColorPalette:
    """パーソナルカラーパレットのバリューオブジェクト"""
    primary_colors: List[str]
    accent_colors: List[str]
    neutral_colors: List[str]
    
    def get_seasonal_colors(self, season: str) -> List[str]:
        """季節に応じた色の組み合わせを返す"""
        # 季節ごとの色調整ロジック（後で実装）
        return self.primary_colors


@dataclass(frozen=True)
class GenerationMetadata:
    """生成メタデータのバリューオブジェクト"""
    generation_time: float
    model_version: str
    confidence_score: float
    estimated_age: int
