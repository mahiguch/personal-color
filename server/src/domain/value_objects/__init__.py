from dataclasses import dataclass
from typing import List, Optional


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
    """生成メタデータのバリューオブジェクト

    互換性のために追加フィールドをオプショナルで保持する。
    - prompt_used: プロンプト文字列（任意）
    - quality_score: 生成品質スコア（任意）
    - estimated_age: 推定年齢（任意）
    - confidence_score: 信頼度（任意、デフォルト0.0）
    """
    model_version: str
    generation_time: float
    confidence_score: float = 0.0
    estimated_age: Optional[int] = None
    prompt_used: str = ""
    quality_score: float = 0.0
