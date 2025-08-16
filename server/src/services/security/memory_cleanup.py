"""
メモリクリーンアップサービス
画像データなどの機密情報を安全に削除
"""

import gc
import os
import tempfile
import logging
from typing import Optional, List, Any
from weakref import WeakSet
import asyncio
from contextlib import asynccontextmanager

logger = logging.getLogger(__name__)


class SecureMemoryManager:
    """セキュアなメモリ管理クラス"""
    
    def __init__(self):
        self._tracked_objects: WeakSet = WeakSet()
        self._temp_files: List[str] = []
        
    def register_sensitive_data(self, obj: Any) -> None:
        """機密データオブジェクトを登録"""
        self._tracked_objects.add(obj)
        logger.debug(f"Registered sensitive object: {type(obj).__name__}")
    
    def clear_memory_immediately(self) -> None:
        """即座にメモリをクリア"""
        # 登録されたオブジェクトをクリア
        for obj in self._tracked_objects:
            try:
                if hasattr(obj, 'clear'):
                    obj.clear()
                elif hasattr(obj, '__dict__'):
                    obj.__dict__.clear()
            except Exception as e:
                logger.warning(f"Failed to clear object: {e}")
        
        # 一時ファイルを削除
        self._clear_temp_files()
        
        # ガベージコレクション強制実行
        gc.collect()
        logger.info("Memory cleanup completed")
    
    def add_temp_file(self, filepath: str) -> None:
        """一時ファイルを追跡対象に追加"""
        self._temp_files.append(filepath)
        logger.debug(f"Added temp file for cleanup: {filepath}")
    
    def _clear_temp_files(self) -> None:
        """一時ファイルを安全に削除"""
        for filepath in self._temp_files[:]:
            try:
                if os.path.exists(filepath):
                    # ファイルをゼロで上書きしてから削除
                    self._secure_delete_file(filepath)
                    logger.debug(f"Securely deleted temp file: {filepath}")
                self._temp_files.remove(filepath)
            except Exception as e:
                logger.error(f"Failed to delete temp file {filepath}: {e}")
    
    def _secure_delete_file(self, filepath: str) -> None:
        """ファイルを安全に削除（複数回上書き）"""
        try:
            file_size = os.path.getsize(filepath)
            
            # 3回ランダムデータで上書き
            with open(filepath, 'r+b') as f:
                for _ in range(3):
                    f.seek(0)
                    f.write(os.urandom(file_size))
                    f.flush()
                    os.fsync(f.fileno())
            
            # ファイル削除
            os.remove(filepath)
            
        except Exception as e:
            logger.error(f"Secure file deletion failed: {e}")
            # 通常の削除にフォールバック
            try:
                os.remove(filepath)
            except Exception:
                pass


# グローバルなメモリマネージャーインスタンス
_memory_manager = SecureMemoryManager()


@asynccontextmanager
async def secure_image_processing(image_data: bytes):
    """画像処理時のセキュアなコンテキストマネージャー"""
    temp_file = None
    
    try:
        # 一時ファイル作成
        with tempfile.NamedTemporaryFile(delete=False, suffix='.tmp') as f:
            f.write(image_data)
            temp_file = f.name
            _memory_manager.add_temp_file(temp_file)
        
        # 画像データを機密データとして登録
        _memory_manager.register_sensitive_data(image_data)
        
        yield temp_file
        
    finally:
        # 確実なクリーンアップ
        if temp_file:
            try:
                _memory_manager._secure_delete_file(temp_file)
            except Exception as e:
                logger.error(f"Failed to cleanup temp file: {e}")
        
        # メモリクリーンアップ
        del image_data
        gc.collect()
        
        logger.info("Secure image processing context cleaned up")


class ImageDataBuffer:
    """画像データ用のセキュアバッファ"""
    
    def __init__(self, data: bytes):
        self._data = bytearray(data)
        self._is_cleared = False
        _memory_manager.register_sensitive_data(self)
    
    @property
    def data(self) -> bytes:
        if self._is_cleared:
            raise RuntimeError("Buffer has been cleared")
        return bytes(self._data)
    
    def clear(self) -> None:
        """バッファを安全にクリア"""
        if not self._is_cleared:
            # メモリをゼロで上書き
            for i in range(len(self._data)):
                self._data[i] = 0
            self._data.clear()
            self._is_cleared = True
            logger.debug("Image buffer cleared securely")
    
    def __del__(self):
        """デストラクタでの確実なクリーンアップ"""
        if not self._is_cleared:
            self.clear()


async def cleanup_request_memory() -> None:
    """リクエスト終了時のメモリクリーンアップ"""
    _memory_manager.clear_memory_immediately()
    
    # 非同期でより徹底的なクリーンアップ
    await asyncio.sleep(0.1)  # 少し待機
    gc.collect()
    logger.debug("Request memory cleanup completed")


def force_memory_cleanup() -> None:
    """強制的なメモリクリーンアップ"""
    _memory_manager.clear_memory_immediately()
    
    # システムレベルのクリーンアップ
    if hasattr(gc, 'set_debug'):
        # デバッグモードでリークチェック
        gc.set_debug(gc.DEBUG_LEAK)
    
    # 複数回ガベージコレクション実行
    for _ in range(3):
        gc.collect()
    
    logger.info("Force memory cleanup completed")


def get_memory_stats() -> dict:
    """メモリ使用状況の統計"""
    return {
        "tracked_objects": len(_memory_manager._tracked_objects),
        "temp_files": len(_memory_manager._temp_files),
        "gc_counts": gc.get_count(),
        "gc_thresholds": gc.get_threshold()
    }