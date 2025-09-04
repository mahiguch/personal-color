"""
Docker設定検証テスト
ポート設定、環境変数、ヘルスチェック設定の整合性をテスト
"""

import pytest
import re
import os
from pathlib import Path


class DockerConfigTest:
    """Docker設定の整合性をテストするクラス"""

    @pytest.fixture(autouse=True)
    def setup(self):
        """テスト用のセットアップ"""
        self.project_root = Path(__file__).parent.parent.parent
        self.dockerfile_path = self.project_root / "Dockerfile"
        self.deploy_script_path = self.project_root / "deploy.sh"

    def test_port_consistency(self):
        """ポート設定の整合性を確認"""
        # Dockerfileからポート設定を抽出
        dockerfile_content = self.dockerfile_path.read_text()
        
        # EXPOSE ポート
        expose_match = re.search(r'EXPOSE\s+(\d+)', dockerfile_content)
        assert expose_match, "DockerfileにEXPOSEポートが見つかりません"
        expose_port = expose_match.group(1)
        
        # CMD/ENTRYPOINTのポート設定
        cmd_match = re.search(r'--port\s+\$\{PORT:-(\d+)\}', dockerfile_content)
        assert cmd_match, "DockerfileのCMDにポート設定が見つかりません"
        cmd_default_port = cmd_match.group(1)
        
        # ヘルスチェックのポート設定
        healthcheck_match = re.search(r'localhost:\$\{PORT:-(\d+)\}', dockerfile_content)
        assert healthcheck_match, "Dockerfileのヘルスチェックにポート設定が見つかりません"
        healthcheck_default_port = healthcheck_match.group(1)
        
        # deploy.shのポート設定
        if self.deploy_script_path.exists():
            deploy_content = self.deploy_script_path.read_text()
            deploy_match = re.search(r'--port=(\d+)', deploy_content)
            assert deploy_match, "deploy.shにポート設定が見つかりません"
            deploy_port = deploy_match.group(1)
            
            # Cloud Runのポートとデフォルトポートが一致することを確認
            assert deploy_port == cmd_default_port == healthcheck_default_port == expose_port, \
                f"ポート設定が不整合: deploy({deploy_port}), cmd({cmd_default_port}), healthcheck({healthcheck_default_port}), expose({expose_port})"

    def test_required_environment_variables(self):
        """必要な環境変数が設定されていることを確認"""
        dockerfile_content = self.dockerfile_path.read_text()
        
        # 必要な環境変数
        required_env_vars = [
            "PYTHONDONTWRITEBYTECODE",
            "PYTHONUNBUFFERED", 
            "PYTHONPATH",
            "GOOGLE_GENAI_USE_VERTEXAI"
        ]
        
        for env_var in required_env_vars:
            assert env_var in dockerfile_content, f"必要な環境変数 {env_var} がDockerfileに見つかりません"

    def test_healthcheck_endpoint_exists(self):
        """ヘルスチェックエンドポイントが存在することを確認"""
        # Dockerfileからヘルスチェックパスを抽出
        dockerfile_content = self.dockerfile_path.read_text()
        healthcheck_match = re.search(r'curl.*?(/api/v1/[^\s"]+)', dockerfile_content)
        assert healthcheck_match, "ヘルスチェックエンドポイントがDockerfileに見つかりません"
        
        healthcheck_path = healthcheck_match.group(1)
        
        # エンドポイントファイルでパスが定義されているか確認
        endpoints_dir = self.project_root / "src" / "api" / "endpoints"
        endpoint_found = False
        
        for py_file in endpoints_dir.rglob("*.py"):
            content = py_file.read_text()
            if healthcheck_path.split("/")[-1] in content:  # パスの最後の部分をチェック
                endpoint_found = True
                break
        
        assert endpoint_found, f"ヘルスチェックエンドポイント {healthcheck_path} が実装されていません"

    def test_dockerfile_build_stages(self):
        """Dockerfileのマルチステージビルドが正しく設定されていることを確認"""
        dockerfile_content = self.dockerfile_path.read_text()
        
        # 必要なステージが存在することを確認
        assert "FROM python:3.10-slim as base" in dockerfile_content, "baseステージが見つかりません"
        assert "FROM base as production" in dockerfile_content, "productionステージが見つかりません"
        
        # セキュリティ設定の確認
        assert "USER appuser" in dockerfile_content, "非rootユーザーが設定されていません"
        assert "groupadd" in dockerfile_content and "useradd" in dockerfile_content, "ユーザー作成が設定されていません"

    def test_requirements_consistency(self):
        """requirements.txtに必要なパッケージが含まれていることを確認"""
        requirements_path = self.project_root / "requirements.txt"
        assert requirements_path.exists(), "requirements.txtが見つかりません"
        
        requirements_content = requirements_path.read_text()
        
        # 必要なパッケージ
        required_packages = [
            "fastapi",
            "uvicorn",
            "google-genai",  # 新SDK
            "pydantic",
        ]
        
        # 禁止されたパッケージ（旧SDKなど）
        forbidden_packages = [
            "google-cloud-aiplatform",  # 旧Vertex AI SDK
            "vertexai",  # 旧Vertex AI SDK
        ]
        
        for package in required_packages:
            assert any(package in line for line in requirements_content.split('\n')), \
                f"必要なパッケージ {package} がrequirements.txtに見つかりません"
        
        for package in forbidden_packages:
            assert not any(package in line for line in requirements_content.split('\n')), \
                f"禁止されたパッケージ {package} がrequirements.txtに含まれています"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])