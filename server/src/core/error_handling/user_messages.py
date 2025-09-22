"""
User Message Generator - Task #016
ユーザーフレンドリーメッセージ生成

機能:
- 多言語対応エラーメッセージ
- コンテキスト考慮したメッセージ
- 解決策の提案
- アクセシビリティ対応
"""

import json
from typing import Dict, Any, Optional, List
from enum import Enum
from dataclasses import dataclass

from .enhanced_exceptions import BaseEnhancedException, ErrorSeverity, ErrorCategory


class Language(Enum):
    """対応言語"""
    JAPANESE = "ja"
    ENGLISH = "en"


class MessageType(Enum):
    """メッセージタイプ"""
    TITLE = "title"           # エラータイトル
    DESCRIPTION = "description"  # 詳細説明
    SOLUTION = "solution"     # 解決策
    CONTACT = "contact"       # 問い合わせ先


@dataclass
class UserMessage:
    """ユーザーメッセージ"""
    title: str
    description: str
    solution: Optional[str] = None
    contact_info: Optional[str] = None
    severity: ErrorSeverity = ErrorSeverity.MEDIUM
    action_required: bool = True
    technical_details: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """辞書形式に変換"""
        return {
            'title': self.title,
            'description': self.description,
            'solution': self.solution,
            'contact_info': self.contact_info,
            'severity': self.severity.value,
            'action_required': self.action_required,
            'technical_details': self.technical_details,
        }


class UserMessageGenerator:
    """ユーザーメッセージ生成器"""
    
    def __init__(self, default_language: Language = Language.JAPANESE):
        self.default_language = default_language
        self.messages = self._load_message_templates()
        self.contact_info = {
            Language.JAPANESE: "サポートまでお問い合わせください（support@example.com）",
            Language.ENGLISH: "Please contact support (support@example.com)"
        }
    
    def _load_message_templates(self) -> Dict[str, Dict[Language, Dict[str, str]]]:
        """メッセージテンプレートを読み込み"""
        return {
            # 検証エラー
            "VALIDATION_ERROR": {
                Language.JAPANESE: {
                    "title": "入力内容に問題があります",
                    "description": "入力された情報の形式が正しくありません。",
                    "solution": "正しい形式で入力し直してください。例: 画像ファイルはJPEG、PNG形式のみ対応しています。"
                },
                Language.ENGLISH: {
                    "title": "Input validation error",
                    "description": "The format of the input information is incorrect.",
                    "solution": "Please enter the correct format. Example: Only JPEG and PNG image files are supported."
                }
            },
            
            # AI サービスエラー
            "AI_SERVICE_ERROR": {
                Language.JAPANESE: {
                    "title": "AI 処理でエラーが発生しました",
                    "description": "AI サービスの処理中に問題が発生しました。",
                    "solution": "しばらく時間をおいて再度お試しください。問題が続く場合はサポートにご連絡ください。"
                },
                Language.ENGLISH: {
                    "title": "AI processing error",
                    "description": "A problem occurred during AI service processing.",
                    "solution": "Please try again after a while. If the problem persists, please contact support."
                }
            },
            
            # 画像処理エラー
            "IMAGE_PROCESSING_ERROR": {
                Language.JAPANESE: {
                    "title": "画像処理エラー",
                    "description": "アップロードされた画像の処理中にエラーが発生しました。",
                    "solution": "以下をご確認ください：\n• 画像ファイル形式がJPEG、PNG、WebPであること\n• ファイルサイズが10MB以下であること\n• 画像が破損していないこと"
                },
                Language.ENGLISH: {
                    "title": "Image processing error",
                    "description": "An error occurred while processing the uploaded image.",
                    "solution": "Please check the following:\n• Image file format is JPEG, PNG, or WebP\n• File size is 10MB or less\n• Image is not corrupted"
                }
            },
            
            # パーソナルカラー分析エラー
            "PERSONAL_COLOR_ERROR": {
                Language.JAPANESE: {
                    "title": "パーソナルカラー分析エラー",
                    "description": "パーソナルカラーの分析中にエラーが発生しました。",
                    "solution": "以下をお試しください：\n• 顔がはっきりと写った画像を使用する\n• 十分な明るさの環境で撮影された画像を使用する\n• 化粧やフィルターの影響が少ない画像を使用する"
                },
                Language.ENGLISH: {
                    "title": "Personal color analysis error", 
                    "description": "An error occurred during personal color analysis.",
                    "solution": "Please try the following:\n• Use an image with a clear face\n• Use an image taken in sufficient lighting\n• Use an image with minimal makeup or filter effects"
                }
            },
            
            # 年齢推定エラー
            "AGE_ESTIMATION_ERROR": {
                Language.JAPANESE: {
                    "title": "年齢推定エラー",
                    "description": "年齢推定の処理中にエラーが発生しました。",
                    "solution": "以下をお試しください：\n• 顔全体がはっきりと写った画像を使用する\n• 1人の顔のみが写った画像を使用する\n• 正面を向いた写真を使用する"
                },
                Language.ENGLISH: {
                    "title": "Age estimation error",
                    "description": "An error occurred during age estimation processing.",
                    "solution": "Please try the following:\n• Use an image with a clear full face\n• Use an image with only one person's face\n• Use a front-facing photo"
                }
            },
            
            # ファッション生成エラー
            "FASHION_GENERATION_ERROR": {
                Language.JAPANESE: {
                    "title": "ファッション画像生成エラー",
                    "description": "ファッション画像の生成中にエラーが発生しました。",
                    "solution": "再度お試しください。問題が続く場合は、異なるスタイル設定をお試しいただくか、サポートにご連絡ください。"
                },
                Language.ENGLISH: {
                    "title": "Fashion image generation error",
                    "description": "An error occurred while generating fashion images.",
                    "solution": "Please try again. If the problem persists, try different style settings or contact support."
                }
            },
            
            # レート制限エラー
            "RATE_LIMIT_EXCEEDED": {
                Language.JAPANESE: {
                    "title": "利用制限に達しました",
                    "description": "一定時間内の利用回数が上限に達しました。",
                    "solution": "しばらく時間をおいて再度お試しください。継続的にご利用の場合は、プレミアムプランのご検討をお願いします。"
                },
                Language.ENGLISH: {
                    "title": "Rate limit exceeded",
                    "description": "The number of uses within a certain period has reached the limit.",
                    "solution": "Please try again after some time. For continuous use, please consider our premium plan."
                }
            },
            
            # リトライ可能エラー
            "RETRYABLE_ERROR": {
                Language.JAPANESE: {
                    "title": "一時的なエラー",
                    "description": "一時的なサービス障害が発生しています。",
                    "solution": "しばらく時間をおいて再度お試しください。"
                },
                Language.ENGLISH: {
                    "title": "Temporary error",
                    "description": "A temporary service failure has occurred.",
                    "solution": "Please try again after a while."
                }
            },
            
            # 致命的エラー
            "FATAL_ERROR": {
                Language.JAPANESE: {
                    "title": "システムエラー",
                    "description": "システム内部でエラーが発生しました。",
                    "solution": "申し訳ございません。管理者が問題を確認中です。しばらく時間をおいて再度お試しください。"
                },
                Language.ENGLISH: {
                    "title": "System error",
                    "description": "An internal system error has occurred.",
                    "solution": "We apologize for the inconvenience. Administrators are checking the issue. Please try again after a while."
                }
            },
            
            # ユーザー向けエラー
            "USER_FACING_ERROR": {
                Language.JAPANESE: {
                    "title": "処理エラー",
                    "description": "処理中にエラーが発生しました。",
                    "solution": "入力内容をご確認の上、再度お試しください。"
                },
                Language.ENGLISH: {
                    "title": "Processing error",
                    "description": "An error occurred during processing.",
                    "solution": "Please check your input and try again."
                }
            },
            
            # システムエラー
            "SYSTEM_ERROR": {
                Language.JAPANESE: {
                    "title": "システムエラー",
                    "description": "システム内部でエラーが発生しました。",
                    "solution": "申し訳ございません。技術チームが問題を調査中です。しばらく時間をおいて再度お試しください。"
                },
                Language.ENGLISH: {
                    "title": "System error",
                    "description": "An internal system error has occurred.",
                    "solution": "We apologize for the inconvenience. Our technical team is investigating the issue. Please try again after a while."
                }
            }
        }
    
    def generate_message(
        self,
        exception: BaseEnhancedException,
        language: Optional[Language] = None,
        include_technical_details: bool = False,
        context: Optional[Dict[str, Any]] = None
    ) -> UserMessage:
        """例外からユーザーメッセージを生成"""
        lang = language or self.default_language
        error_code = exception.error_code
        
        # テンプレート取得
        template = self.messages.get(error_code, {}).get(lang, {})
        if not template:
            # フォールバック: デフォルトメッセージ
            template = self._get_fallback_template(lang, exception.severity)
        
        # コンテキスト情報を考慮したメッセージ生成
        title = self._customize_title(template.get("title", "エラーが発生しました"), exception, context)
        description = self._customize_description(template.get("description", ""), exception, context)
        solution = self._customize_solution(template.get("solution", ""), exception, context)
        
        # 技術詳細
        technical_details = None
        if include_technical_details:
            technical_details = f"エラーコード: {error_code}\n詳細: {exception.message}"
        
        # 問い合わせ先
        contact_info = None
        if exception.severity in [ErrorSeverity.HIGH, ErrorSeverity.CRITICAL]:
            contact_info = self.contact_info.get(lang)
        
        return UserMessage(
            title=title,
            description=description,
            solution=solution,
            contact_info=contact_info,
            severity=exception.severity,
            action_required=exception.severity != ErrorSeverity.LOW,
            technical_details=technical_details
        )
    
    def _get_fallback_template(self, lang: Language, severity: ErrorSeverity) -> Dict[str, str]:
        """フォールバックテンプレート取得"""
        if lang == Language.JAPANESE:
            if severity == ErrorSeverity.CRITICAL:
                return {
                    "title": "重大なエラー",
                    "description": "システムで重大なエラーが発生しました。",
                    "solution": "管理者にお問い合わせください。"
                }
            else:
                return {
                    "title": "エラーが発生しました",
                    "description": "処理中にエラーが発生しました。",
                    "solution": "しばらく時間をおいて再度お試しください。"
                }
        else:  # English
            if severity == ErrorSeverity.CRITICAL:
                return {
                    "title": "Critical Error",
                    "description": "A critical error has occurred in the system.",
                    "solution": "Please contact the administrator."
                }
            else:
                return {
                    "title": "An error occurred",
                    "description": "An error occurred during processing.",
                    "solution": "Please try again after a while."
                }
    
    def _customize_title(self, title: str, exception: BaseEnhancedException, context: Optional[Dict[str, Any]]) -> str:
        """タイトルをカスタマイズ"""
        # 特定の条件に基づいてタイトルを調整
        if context and context.get("user_operation"):
            operation = context["user_operation"]
            if operation == "image_upload":
                return title.replace("エラー", "画像アップロードエラー")
            elif operation == "analysis":
                return title.replace("エラー", "分析エラー")
        
        return title
    
    def _customize_description(self, description: str, exception: BaseEnhancedException, context: Optional[Dict[str, Any]]) -> str:
        """説明をカスタマイズ"""
        # 詳細情報を追加
        if hasattr(exception, 'details') and exception.details:
            if exception.details.get('field'):
                field = exception.details['field']
                description += f"\n問題のある項目: {field}"
        
        return description
    
    def _customize_solution(self, solution: str, exception: BaseEnhancedException, context: Optional[Dict[str, Any]]) -> str:
        """解決策をカスタマイズ"""
        # リトライ可能な場合の情報追加
        if exception.retry_possible and exception.max_retries > 0:
            solution += f"\n\n自動的に{exception.max_retries}回まで再試行されます。"
        
        # レート制限の場合の具体的な時間
        if exception.error_code == "RATE_LIMIT_EXCEEDED" and exception.details.get('retry_after'):
            retry_after = exception.details['retry_after']
            if retry_after < 60:
                solution += f"\n{retry_after}秒後に再度お試しください。"
            else:
                minutes = retry_after // 60
                solution += f"\n{minutes}分後に再度お試しください。"
        
        return solution
    
    def generate_success_message(
        self,
        operation: str,
        language: Optional[Language] = None,
        details: Optional[Dict[str, Any]] = None
    ) -> Dict[str, str]:
        """成功メッセージを生成"""
        lang = language or self.default_language
        
        success_templates = {
            "image_upload": {
                Language.JAPANESE: {
                    "title": "画像アップロード完了",
                    "description": "画像が正常にアップロードされました。"
                },
                Language.ENGLISH: {
                    "title": "Image upload completed",
                    "description": "The image has been uploaded successfully."
                }
            },
            "analysis_complete": {
                Language.JAPANESE: {
                    "title": "分析完了",
                    "description": "パーソナルカラー分析が完了しました。"
                },
                Language.ENGLISH: {
                    "title": "Analysis completed",
                    "description": "Personal color analysis has been completed."
                }
            },
            "generation_complete": {
                Language.JAPANESE: {
                    "title": "生成完了",
                    "description": "ファッションコーディネートが生成されました。"
                },
                Language.ENGLISH: {
                    "title": "Generation completed",
                    "description": "Fashion coordination has been generated."
                }
            }
        }
        
        template = success_templates.get(operation, {}).get(lang, {})
        if not template:
            # フォールバック
            if lang == Language.JAPANESE:
                template = {"title": "処理完了", "description": "処理が正常に完了しました。"}
            else:
                template = {"title": "Processing completed", "description": "Processing has been completed successfully."}
        
        return template


# 共有インスタンス
message_generator = UserMessageGenerator()


def generate_user_friendly_message(
    exception: BaseEnhancedException,
    language: Language = Language.JAPANESE,
    include_technical: bool = False,
    context: Optional[Dict[str, Any]] = None
) -> UserMessage:
    """ユーザーフレンドリーメッセージ生成のヘルパー関数"""
    return message_generator.generate_message(
        exception, 
        language, 
        include_technical, 
        context
    )
