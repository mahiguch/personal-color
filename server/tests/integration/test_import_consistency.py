"""
Import整合性テスト
デプロイ前にimportエラーやAPIの不整合を検出
"""

import pytest
import importlib
import sys
import ast
import os
from pathlib import Path


class ImportConsistencyTest:
    """Import整合性をテストするクラス"""

    @pytest.fixture(autouse=True)
    def setup(self):
        """テスト用のセットアップ"""
        self.src_path = Path(__file__).parent.parent.parent / "src"
        self.forbidden_imports = [
            "google.cloud.aiplatform",  # 旧Vertex AI SDK
            "vertexai.generative_models",  # 旧Vertex AI SDK
        ]
        self.required_imports = [
            "google.genai",  # 新Google Gen AI SDK
        ]

    def test_no_forbidden_imports(self):
        """禁止されたimportが使用されていないことを確認"""
        violations = []
        
        for py_file in self.src_path.rglob("*.py"):
            with open(py_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            for forbidden in self.forbidden_imports:
                if forbidden in content:
                    violations.append(f"{py_file}: {forbidden}")
        
        assert not violations, f"禁止されたimportが見つかりました: {violations}"

    def test_all_imports_loadable(self):
        """すべてのモジュールが正常にimportできることを確認"""
        failures = []
        
        for py_file in self.src_path.rglob("*.py"):
            if "__pycache__" in str(py_file):
                continue
                
            # Pythonモジュールパスに変換
            relative_path = py_file.relative_to(self.src_path.parent)
            module_path = str(relative_path.with_suffix('')).replace('/', '.')
            
            try:
                importlib.import_module(module_path)
            except Exception as e:
                failures.append(f"{module_path}: {str(e)}")
        
        assert not failures, f"Import失敗: {failures}"

    def test_gemini_service_api_consistency(self):
        """Gemini ServiceのAPIが他の場所での使用と一致することを確認"""
        try:
            from src.services.gemini_service import get_gemini_service
            from unittest.mock import patch, MagicMock
            
            # Gemini SDKをモック化してimportエラーを回避
            with patch('src.services.gemini_service.genai') as mock_genai:
                mock_genai.Client.return_value = MagicMock()
                service = get_gemini_service()
        except ImportError as e:
            pytest.skip(f"Gemini service not available in test environment: {e}")
        
        # 必要なメソッドの存在確認
        required_methods = [
            'health_check',  # check_healthではない
            'generate_makeup_explanation',
            'get_cache_stats',
            'clear_cache'
        ]
        
        for method_name in required_methods:
            assert hasattr(service, method_name), f"GeminiService.{method_name}が存在しません"
        
        # health_checkの戻り値型確認
        import asyncio
        health_result = asyncio.run(service.health_check())
        assert isinstance(health_result, dict), "health_check()の戻り値はdictである必要があります"
        assert "status" in health_result, "health_check()の戻り値には'status'キーが必要です"

    def test_deprecated_methods_not_used(self):
        """非推奨メソッドが使用されていないことを確認"""
        deprecated_patterns = [
            "check_health()",  # → health_check()
            "analyze_personal_color(",  # 削除されたメソッド
            "GeminiService()",  # → get_gemini_service()
        ]
        
        violations = []
        
        for py_file in self.src_path.rglob("*.py"):
            with open(py_file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            for pattern in deprecated_patterns:
                if pattern in content:
                    # シングルトンパターンの正当な使用を除外
                    if pattern == "GeminiService()" and "_gemini_service_instance = GeminiService()" in content:
                        continue
                    violations.append(f"{py_file}: {pattern}")
        
        assert not violations, f"非推奨パターンが見つかりました: {violations}"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])