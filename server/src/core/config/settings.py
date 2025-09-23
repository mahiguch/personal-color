"""
アプリケーション設定
環境変数とデフォルト値の管理
"""

from pydantic_settings import BaseSettings
from pydantic import Field, ConfigDict
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
    allowed_origins: str = Field(
        default="http://localhost:3000,http://127.0.0.1:3000",
        description="許可するオリジン（カンマ区切り）",
    )

    # Google Cloud設定
    google_cloud_project: str = Field(default="", description="Google Cloudプロジェクト ID")
    vertex_ai_location: str = Field(
        default="asia-northeast1", description="Vertex AI リージョン"
    )
    gemini_model_name: str = Field(
        default="gemini-2.5-flash", description="使用するGeminiモデル名"
    )

    # Google Gen AI SDK設定
    use_vertexai: bool = Field(default=True, description="Vertex AI使用フラグ")
    
    # Virtual Try-On 設定
    virtual_try_on_model: str = Field(
        default="virtual-try-on-preview-08-04",
        description="使用するVirtual Try-Onモデル ID"
    )
    virtual_try_on_sample_count: int = Field(
        default=1,
        description="Virtual Try-On で生成するサンプル数"
    )
    virtual_try_on_add_watermark: bool = Field(
        default=True,
        description="Virtual Try-On 画像に透かしを付与するか"
    )
    virtual_try_on_person_generation: str = Field(
        default="allow_adult",
        description="Virtual Try-On で人物生成を許可する範囲"
    )
    virtual_try_on_safety_setting: str = Field(
        default="block_medium_and_above",
        description="Virtual Try-On のセーフティ設定"
    )
    virtual_try_on_default_product_image_uris: str = Field(
        default="",
        description="Virtual Try-On に使用するデフォルト商品画像URI（カンマ区切り）"
    )
    virtual_try_on_timeout_seconds: int = Field(
        default=60,
        description="Virtual Try-On API呼び出しのタイムアウト(秒)"
    )

    # Imagen 4.0 設定
    imagen_model_name: str = Field(
        default="imagen-4.0-generate-001", description="使用するImagenモデル名"
    )

    # Firebase設定
    firebase_project_id: str = Field(
        default="personal-color-469007", description="Firebase プロジェクト ID"
    )
    firebase_credentials_path: str = Field(
        default="", description="Firebase認証情報ファイルのパス"
    )

    # API設定
    max_image_size_mb: int = Field(default=10, description="最大画像サイズ(MB)")
    request_timeout_seconds: int = Field(default=30, description="リクエストタイムアウト(秒)")
    max_retry_attempts: int = Field(default=3, description="最大リトライ回数")
    
    # 機能フラグ
    enhanced_diagnosis_enabled: bool = Field(
        default=True, description="拡張診断（年代・性別推定）の有効化"
    )
    
    # AI画像生成設定
    ai_image_generation_enabled: bool = Field(default=True, description="AI画像生成機能の有効化")
    ai_image_max_retries: int = Field(default=3, description="AI画像生成の最大リトライ回数")
    ai_image_timeout_seconds: int = Field(default=30, description="AI画像生成のタイムアウト(秒)")

    # セキュリティ設定
    api_key: str = Field(default="", description="API認証キー")
    rate_limit_per_minute: int = Field(default=60, description="分間レート制限")

    # レート制限詳細設定
    rate_limit_default: int = Field(default=60, description="デフォルトレート制限")
    rate_limit_diagnosis: int = Field(default=10, description="診断レート制限")
    rate_limit_burst: int = Field(default=5, description="バーストレート制限")

    # パフォーマンス設定
    worker_count: int = Field(default=4, description="ワーカー数")
    max_concurrent_requests: int = Field(default=100, description="最大同時リクエスト数")

    # 監視設定
    enable_metrics: bool = Field(default=True, description="メトリクス有効化")
    enable_tracing: bool = Field(default=True, description="トレーシング有効化")

    # ログ設定
    log_level: str = Field(default="INFO", description="ログレベル")
    log_format: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        description="ログフォーマット",
    )

    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"  # 未定義の環境変数を無視
    )


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
