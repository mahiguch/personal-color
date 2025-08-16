"""
アプリケーション設定
環境変数とデフォルト値の管理
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List
import os
from functools import lru_cache


class Settings(BaseSettings):
    """アプリケーション設定クラス"""
    
    # 基本設定
    environment: str = Field(default="development", description="実行環境")
    debug: bool = Field(default=True, description="デバッグモード")
    host: str = Field(default="0.0.0.0", description="サーバーホスト")
    port: int = Field(default=8000, description="サーバーポート")
    
    # CORS設定
    allowed_origins: List[str] = Field(
        default=["http://localhost:3000", "http://127.0.0.1:3000"],
        description="許可するオリジン"
    )
    
    # Google Cloud設定
    google_cloud_project: str = Field(
        default="", 
        description="Google Cloudプロジェクト ID"
    )
    vertex_ai_location: str = Field(
        default="us-central1", 
        description="Vertex AI リージョン"
    )
    gemini_model_name: str = Field(
        default="gemini-2.5-pro-002", 
        description="使用するGeminiモデル名"
    )
    
    # API設定
    max_image_size_mb: int = Field(default=10, description="最大画像サイズ(MB)")
    request_timeout_seconds: int = Field(default=30, description="リクエストタイムアウト(秒)")
    max_retry_attempts: int = Field(default=3, description="最大リトライ回数")
    
    # セキュリティ設定
    api_key: str = Field(default="", description="API認証キー")
    rate_limit_per_minute: int = Field(default=60, description="分間レート制限")
    
    # ログ設定
    log_level: str = Field(default="INFO", description="ログレベル")
    log_format: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        description="ログフォーマット"
    )
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """設定のシングルトンインスタンスを取得"""
    return Settings()


# 開発環境用のデフォルト設定
def get_development_settings() -> Settings:
    """開発環境用設定を取得"""
    settings = Settings()
    settings.debug = True
    settings.environment = "development"
    settings.log_level = "DEBUG"
    return settings


# 本番環境用のデフォルト設定
def get_production_settings() -> Settings:
    """本番環境用設定を取得"""
    settings = Settings()
    settings.debug = False
    settings.environment = "production"
    settings.log_level = "INFO"
    settings.allowed_origins = []  # 本番では明示的に設定
    return settings