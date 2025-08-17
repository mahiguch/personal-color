"""Firebase App Check verification middleware."""

import logging
from typing import Callable
from fastapi import HTTPException, Request, Response, status
from firebase_admin import app_check
import firebase_admin
from firebase_admin import credentials

logger = logging.getLogger(__name__)


class AppCheckMiddleware:
    """Firebase App Check トークン検証ミドルウェア"""
    
    def __init__(
        self, 
        project_id: str,
        skip_verification: bool = False
    ):
        """
        Args:
            project_id: Firebase プロジェクト ID
            skip_verification: 検証をスキップするかどうか（開発環境用）
        """
        self.project_id = project_id
        self.skip_verification = skip_verification
        self._initialize_firebase()
    
    def _initialize_firebase(self) -> None:
        """Firebase Admin SDK を初期化"""
        try:
            # Firebase Admin が既に初期化されているかチェック
            firebase_admin.get_app()
        except ValueError:
            # 初期化されていない場合、デフォルト認証情報で初期化
            try:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(
                    cred, 
                    {'projectId': self.project_id}
                )
                logger.info("Firebase Admin SDK initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
                raise
    
    async def __call__(
        self, 
        request: Request, 
        call_next: Callable[[Request], Response]
    ) -> Response:
        """ミドルウェア実行"""
        
        # 検証をスキップする場合
        if self.skip_verification:
            logger.debug("App Check verification skipped")
            return await call_next(request)
        
        # ヘルスチェックやテストエンドポイントはスキップ
        if self._should_skip_path(request.url.path):
            return await call_next(request)
        
        # App Check トークンを検証
        try:
            self._verify_app_check_token(request)
            logger.debug("App Check token verified successfully")
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"App Check verification error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="App Check verification failed"
            )
        
        return await call_next(request)
    
    def _should_skip_path(self, path: str) -> bool:
        """検証をスキップするパスかどうか判定"""
        skip_paths = [
            "/docs",
            "/redoc", 
            "/openapi.json",
            "/health",
            "/api/v1/diagnose/test"  # テスト用エンドポイント
        ]
        return any(path.startswith(skip_path) for skip_path in skip_paths)
    
    def _verify_app_check_token(self, request: Request) -> None:
        """App Check トークンを検証"""
        # ヘッダーからトークンを取得
        app_check_token = request.headers.get("X-Firebase-AppCheck")
        
        if not app_check_token:
            logger.warning("App Check token missing from request")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="App Check token required"
            )
        
        try:
            # App Check トークンを検証
            decoded_token = app_check.verify_token(app_check_token)
            
            # プロジェクト ID を確認
            if decoded_token.get('aud') != [self.project_id]:
                logger.warning(f"Invalid project ID in token: {decoded_token.get('aud')}")
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid App Check token"
                )
            
            logger.debug(f"App Check token verified for app: {decoded_token.get('app_id')}")
            
        except app_check.InvalidAppCheckTokenError as e:
            logger.warning(f"Invalid App Check token: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid App Check token"
            )
        except Exception as e:
            logger.error(f"App Check verification error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="App Check verification failed"
            )