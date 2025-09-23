"""
Task #017: セキュリティ強化機能のデモンストレーション
統合セキュリティシステムの動作確認
"""

import asyncio
import tempfile
import os
from PIL import Image
import io
import json
import logging

from src.core.security.image_security import validate_uploaded_image, ImageSecurityError
from src.core.security.privacy_log_handler import get_privacy_logger, audit_action
from src.core.security.input_validation import SecurityValidator, InputValidationError
from src.services.security.memory_cleanup import secure_image_processing, cleanup_request_memory


# ログ設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


async def demo_image_security_validation():
    """画像セキュリティ検証のデモ"""
    print("\n=== 画像セキュリティ検証デモ ===")

    # 1. 有効な画像の作成とテスト
    print("\n1. 有効な画像のテスト")
    img = Image.new('RGB', (300, 200), color='blue')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    valid_image_data = img_bytes.getvalue()

    try:
        result = validate_uploaded_image(valid_image_data, "test.jpg")
        print(f"✅ 有効な画像: {result['format']} {result['size']}, セキュリティスコア: {result['security_score']:.2f}")
        print(f"   ファイルハッシュ: {result['file_hash'][:16]}...")
    except ImageSecurityError as e:
        print(f"❌ エラー: {e}")

    # 2. 危険なファイルシグネチャのテスト
    print("\n2. 危険なファイルシグネチャのテスト")
    dangerous_data = b'\x4d\x5a' + b'fake_exe_content'  # PE実行ファイル

    try:
        validate_uploaded_image(dangerous_data, "malicious.jpg")
        print("❌ 危険なファイルが通過してしまいました")
    except ImageSecurityError as e:
        print(f"✅ 危険なファイルをブロック: {e}")

    # 3. 大きすぎるファイルのテスト
    print("\n3. ファイルサイズ制限のテスト")
    large_data = b'\xff\xd8\xff' + b'x' * (11 * 1024 * 1024)  # 11MB

    try:
        validate_uploaded_image(large_data, "huge.jpg")
        print("❌ 大きすぎるファイルが通過してしまいました")
    except ImageSecurityError as e:
        print(f"✅ 大きすぎるファイルをブロック: {e}")


def demo_pii_sanitization():
    """PII除去機能のデモ"""
    print("\n=== PII除去機能デモ ===")

    from src.core.security.privacy_log_handler import AdvancedPIISanitizer

    sanitizer = AdvancedPIISanitizer()

    # テストデータ
    test_cases = [
        "連絡先: user@example.com",
        "電話番号: 090-1234-5678",
        "サーバーIP: 192.168.1.100",
        'ユーザーID: user_id: "abc123def456"',
        "IPアドレス: 2001:db8::1",
        "クレジットカード: 1234 5678 9012 3456"
    ]

    for i, test_text in enumerate(test_cases, 1):
        print(f"\n{i}. テストケース: {test_text}")
        result = sanitizer.sanitize_text(test_text)
        print(f"   除去後: {result['sanitized_text']}")
        print(f"   検出PII: {len(result['detected_pii'])} 件")

        for pii in result['detected_pii']:
            print(f"     - {pii['type']}: {pii['count']} 個 (信頼度: {pii['confidence']:.2f})")

    # JSON データのサニタイズ
    print("\n--- JSON データのサニタイズ ---")
    json_data = {
        "user_email": "sensitive@test.com",
        "user_phone": "03-1234-5678",
        "server_info": {
            "ip": "10.0.0.1",
            "session_id": "sess_abcdef123456789"
        },
        "safe_data": "これは安全なデータです"
    }

    print(f"元のJSON: {json.dumps(json_data, ensure_ascii=False, indent=2)}")

    sanitized_json = sanitizer.sanitize_json(json_data)
    print(f"除去後JSON: {json.dumps(sanitized_json, ensure_ascii=False, indent=2)}")


def demo_privacy_protected_logging():
    """プライバシー保護ログのデモ"""
    print("\n=== プライバシー保護ログデモ ===")

    # プライバシー保護ログ
    privacy_logger = get_privacy_logger("demo")

    # 通常ログ（PII含む）
    print("\n1. 通常ログ出力（PII自動除去）")
    privacy_logger.info("ユーザー user@example.com からのリクエスト処理開始")
    privacy_logger.warning("異常なアクセス検出: IP 192.168.1.100 から")

    # 監査ログ
    print("\n2. 監査ログ出力")
    audit_action("user_login", user_email="audit@test.com", client_ip="10.0.0.1", result="success")
    audit_action("file_upload", filename="secure_document.pdf", user_id="user_12345")

    # エラーログ（例外情報含む）
    print("\n3. エラーログ出力")
    try:
        raise ValueError("テストエラー: 機密情報 secret_key_abc123")
    except ValueError as e:
        privacy_logger.error("処理中にエラーが発生", {"error_details": str(e)}, exception=e)

    # 統計情報
    stats = privacy_logger.get_privacy_stats()
    print(f"\n4. プライバシー保護統計")
    print(f"   - 検出ルール数: {stats['sanitizer_stats']['total_rules']}")
    print(f"   - 監査エントリ数: {stats['audit_entries']}")


def demo_input_validation():
    """入力検証のデモ"""
    print("\n=== 入力検証デモ ===")

    # パーソナルカラー検証
    print("\n1. パーソナルカラー検証")
    valid_colors = ["spring", "summer", "autumn", "winter"]
    invalid_colors = ["invalid<script>", "malicious", ""]

    for color in valid_colors:
        try:
            validated = SecurityValidator.validate_personal_color_type(color)
            print(f"✅ 有効: {color} -> {validated}")
        except InputValidationError as e:
            print(f"❌ エラー: {e}")

    for color in invalid_colors:
        try:
            validated = SecurityValidator.validate_personal_color_type(color)
            print(f"❌ 無効な値が通過: {color}")
        except InputValidationError as e:
            print(f"✅ 無効値をブロック: {color} -> {e}")

    # URL検証
    print("\n2. Amazon URL検証")
    valid_urls = [
        "https://amazon.co.jp/product/123",
        "https://www.amazon.com/dp/B08XYZ",
        "https://amzn.to/3abc123"
    ]

    invalid_urls = [
        "javascript:alert('xss')",
        "https://malicious-site.com/fake-amazon",
        "data:text/html,<script>alert('xss')</script>"
    ]

    for url in valid_urls:
        result = SecurityValidator.validate_amazon_url(url)
        print(f"✅ 有効URL: {url} -> {result}")

    for url in invalid_urls:
        result = SecurityValidator.validate_amazon_url(url)
        print(f"❌ 無効URL: {url} -> {result}")

    # 文字列サニタイズ
    print("\n3. 文字列サニタイズ")
    dangerous_strings = [
        '<script>alert("xss")</script>',
        'javascript:evil()',
        'onclick="malicious()"',
        '普通のテキスト'
    ]

    for text in dangerous_strings:
        sanitized = SecurityValidator.sanitize_string(text)
        print(f"元の文字列: {text}")
        print(f"サニタイズ後: {sanitized}")
        print()


async def demo_secure_memory_management():
    """セキュアメモリ管理のデモ"""
    print("\n=== セキュアメモリ管理デモ ===")

    # 画像データでのセキュア処理
    print("\n1. セキュア画像処理")
    img = Image.new('RGB', (100, 100), color='green')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    image_data = img_bytes.getvalue()

    print(f"元の画像データサイズ: {len(image_data)} bytes")

    async with secure_image_processing(image_data) as temp_file:
        print(f"一時ファイル作成: {temp_file}")
        print(f"ファイル存在確認: {os.path.exists(temp_file)}")

        # ファイル内容の確認
        with open(temp_file, 'rb') as f:
            file_size = len(f.read())
        print(f"一時ファイルサイズ: {file_size} bytes")

    print(f"処理後ファイル存在確認: {os.path.exists(temp_file)}")

    # メモリクリーンアップ
    print("\n2. メモリクリーンアップ")
    await cleanup_request_memory()
    print("リクエストメモリクリーンアップ完了")


async def demo_integrated_security_workflow():
    """統合セキュリティワークフローのデモ"""
    print("\n=== 統合セキュリティワークフローデモ ===")

    privacy_logger = get_privacy_logger("integrated_demo")

    # 1. 画像アップロードシミュレーション
    print("\n1. 画像アップロードフロー")

    # 有効な画像を作成
    img = Image.new('RGB', (256, 256), color='red')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    image_data = img_bytes.getvalue()

    try:
        # セキュリティ検証
        security_result = validate_uploaded_image(image_data, "user_photo.jpg")
        privacy_logger.info(
            "画像アップロード検証完了",
            {
                "security_score": security_result['security_score'],
                "file_size": len(image_data),
                "user_ip": "192.168.1.100"  # この情報は自動的にマスキングされる
            }
        )

        # セキュア処理
        async with secure_image_processing(image_data) as temp_file:
            privacy_logger.info(f"安全な画像処理開始: ファイルサイズ {len(image_data)} bytes")

            # 監査ログ
            audit_action(
                "image_processing",
                file_hash=security_result['file_hash'][:16],
                security_score=security_result['security_score'],
                user_context={"user_email": "demo@example.com"}  # 自動的にマスキングされる
            )

        privacy_logger.info("画像処理完了、一時ファイル削除済み")

    except ImageSecurityError as e:
        privacy_logger.error(f"画像セキュリティエラー: {e}")

    # 2. リクエスト完了処理
    print("\n2. リクエスト完了処理")
    await cleanup_request_memory()
    privacy_logger.info("リクエスト処理完了、メモリクリーンアップ済み")

    # 3. 統計情報の出力
    print("\n3. セキュリティ統計")
    stats = privacy_logger.get_privacy_stats()
    print(f"プライバシー保護統計: {json.dumps(stats, ensure_ascii=False, indent=2)}")


async def main():
    """メインデモ関数"""
    print("🔒 Personal Color App - Task #017: セキュリティ強化機能デモ")
    print("=" * 70)

    try:
        # 各セキュリティ機能のデモ
        await demo_image_security_validation()
        demo_pii_sanitization()
        demo_privacy_protected_logging()
        demo_input_validation()
        await demo_secure_memory_management()
        await demo_integrated_security_workflow()

        print("\n" + "=" * 70)
        print("✅ 全てのセキュリティ機能デモが正常に完了しました")
        print("🔒 Task #017: セキュリティ強化 - 実装完了")

    except Exception as e:
        logger.error(f"デモ実行中にエラーが発生: {e}")
        print(f"\n❌ デモ実行エラー: {e}")


if __name__ == "__main__":
    asyncio.run(main())