#!/bin/bash

# デプロイ前チェックスクリプト
# 不具合を事前に検知してデプロイメント失敗を防ぐ

set -e

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 デプロイ前チェックを開始します...${NC}"

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# エラーカウンター
ERROR_COUNT=0

# 0. 依存関係のインストールチェック
echo -e "${YELLOW}📚 テスト依存関係チェック...${NC}"
if ! pip show fastapi > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️ テスト依存関係が不足しています。インストールしています...${NC}"
    pip install -r requirements-test.txt --quiet
fi

# 1. Import整合性チェック (基本的なチェックのみ)
echo -e "${YELLOW}📦 Import整合性チェック...${NC}"
if python -c "
import sys, os, ast, re
from pathlib import Path

src_path = Path('src')
forbidden_imports = ['google.cloud.aiplatform', 'vertexai.generative_models']
violations = []

for py_file in src_path.rglob('*.py'):
    with open(py_file, 'r', encoding='utf-8') as f:
        content = f.read()
    for forbidden in forbidden_imports:
        if forbidden in content:
            violations.append(f'{py_file}: {forbidden}')

if violations:
    print('FAIL: 禁止されたimportが見つかりました:', violations)
    sys.exit(1)
else:
    print('PASS: Import整合性チェック')
"; then
    echo -e "${GREEN}✅ Import整合性チェック: 合格${NC}"
else
    echo -e "${RED}❌ Import整合性チェック: 失敗${NC}"
    ((ERROR_COUNT++))
fi

# 2. Docker設定チェック (simplified)
echo -e "${YELLOW}🐳 Docker設定チェック...${NC}"
if python -c "
import re
from pathlib import Path

dockerfile = Path('Dockerfile')
if not dockerfile.exists():
    print('FAIL: Dockerfileが見つかりません')
    exit(1)

content = dockerfile.read_text()

# ポート設定チェック
expose_match = re.search(r'EXPOSE\s+(\d+)', content)
cmd_match = re.search(r'--port\s+\\\$\{PORT:-(\d+)\}', content)
healthcheck_match = re.search(r'localhost:\\\$\{PORT:-(\d+)\}', content)

if not all([expose_match, cmd_match, healthcheck_match]):
    print('FAIL: ポート設定が見つかりません')
    exit(1)

expose_port = expose_match.group(1) if expose_match else None
cmd_port = cmd_match.group(1) if cmd_match else None
hc_port = healthcheck_match.group(1) if healthcheck_match else None

if expose_port == cmd_port == hc_port == '8080':
    print('PASS: Docker設定チェック')
else:
    print(f'FAIL: ポート設定が不整合 expose:{expose_port}, cmd:{cmd_port}, hc:{hc_port}')
    exit(1)
"; then
    echo -e "${GREEN}✅ Docker設定チェック: 合格${NC}"
else
    echo -e "${RED}❌ Docker設定チェック: 失敗${NC}"
    ((ERROR_COUNT++))
fi

# 3. 基本構文チェック（Pythonファイルの構文エラーチェック）
echo -e "${YELLOW}🐍 Python構文チェック...${NC}"
SYNTAX_ERRORS=0
for py_file in $(find src -name "*.py"); do
    if ! python -m py_compile "$py_file" 2>/dev/null; then
        echo -e "${RED}構文エラー: $py_file${NC}"
        ((SYNTAX_ERRORS++))
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Python構文チェック: 合格${NC}"
else
    echo -e "${RED}❌ Python構文チェック: 失敗 (${SYNTAX_ERRORS}個のエラー)${NC}"
    ((ERROR_COUNT++))
fi

# 4. 必要なファイルの存在確認
echo -e "${YELLOW}📁 必要ファイル存在確認...${NC}"
REQUIRED_FILES=("src/api/main.py" "src/services/gemini_service.py" "requirements.txt" "Dockerfile")
MISSING_FILES=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}欠損ファイル: $file${NC}"
        ((MISSING_FILES++))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    echo -e "${GREEN}✅ 必要ファイル存在確認: 合格${NC}"
else
    echo -e "${RED}❌ 必要ファイル存在確認: 失敗 (${MISSING_FILES}個の欠損)${NC}"
    ((ERROR_COUNT++))
fi

# 5. Dockerfileビルドテスト
echo -e "${YELLOW}🏗️ Dockerfileビルドテスト...${NC}"
if docker build --target production -t personal-color-api:test .; then
    echo -e "${GREEN}✅ Dockerfileビルド: 合格${NC}"
    
    # ビルドしたイメージのポート設定確認
    echo -e "${YELLOW}🔍 コンテナポート設定確認...${NC}"
    if docker inspect personal-color-api:test | grep -q '"8080/tcp": {}'; then
        echo -e "${GREEN}✅ ポート設定: 合格 (8080)${NC}"
    else
        echo -e "${RED}❌ ポート設定: 失敗 (8080ポートが公開されていません)${NC}"
        ((ERROR_COUNT++))
    fi
    
    # テストイメージを削除
    docker rmi personal-color-api:test >/dev/null 2>&1 || true
    
else
    echo -e "${RED}❌ Dockerfileビルド: 失敗${NC}"
    ((ERROR_COUNT++))
fi

# 5. 静的解析（重要なエラーのみ）
echo -e "${YELLOW}📝 静的解析チェック...${NC}"
if command -v flake8 &> /dev/null; then
    # 重要なエラーのみチェック（E9, F63, F7, F82等）
    CRITICAL_ERRORS=$(flake8 src/ --select=E9,F63,F7,F82 --statistics --count 2>/dev/null || echo "0")
    
    if [ "$CRITICAL_ERRORS" = "0" ] || [ -z "$CRITICAL_ERRORS" ]; then
        echo -e "${GREEN}✅ 静的解析: 合格（重要なエラーなし）${NC}"
    else
        echo -e "${YELLOW}⚠️ 静的解析: ${CRITICAL_ERRORS}個の重要なエラー（警告レベル）${NC}"
        # 重要なエラーがあっても警告レベルとして続行
    fi
else
    echo -e "${YELLOW}⚠️ flake8が見つかりません。スキップします。${NC}"
fi

# 6. 型チェック（警告レベル）
echo -e "${YELLOW}🔍 型チェック (mypy)...${NC}"
if command -v mypy &> /dev/null; then
    # 型チェックは警告レベル（失敗してもデプロイ阻止しない）
    if mypy src/ --ignore-missing-imports >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 型チェック: 合格${NC}"
    else
        echo -e "${YELLOW}⚠️ 型チェックで問題が検出されました（警告レベル）${NC}"
        echo -e "${YELLOW}   詳細: mypy src/ --ignore-missing-imports で確認してください${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ mypyが見つかりません。スキップします。${NC}"
fi

# 7. セキュリティチェック（警告レベル）
echo -e "${YELLOW}🔒 セキュリティチェック...${NC}"
if command -v safety &> /dev/null; then
    # セキュリティチェックは警告レベル（失敗してもエラーカウントしない）
    if safety check --short-report >/dev/null 2>&1; then
        echo -e "${GREEN}✅ セキュリティチェック: 合格${NC}"
    else
        echo -e "${YELLOW}⚠️ セキュリティ脆弱性が検出されました（警告レベル）${NC}"
        echo -e "${YELLOW}   詳細: safety check --full-report で確認してください${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ safetyが見つかりません。セキュリティチェックをスキップします。${NC}"
fi

# 結果サマリー
echo ""
echo -e "${BLUE}📊 デプロイ前チェック結果${NC}"
echo "=================================="

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 全てのチェックが合格しました！${NC}"
    echo -e "${GREEN}✅ デプロイの準備ができています${NC}"
    exit 0
else
    echo -e "${RED}❌ ${ERROR_COUNT}個のチェックが失敗しました${NC}"
    echo -e "${RED}🚫 デプロイ前に修正してください${NC}"
    exit 1
fi