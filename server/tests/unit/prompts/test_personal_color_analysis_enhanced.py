import pytest

from src.prompts.personal_color_analysis import PersonalColorPrompt


class TestPersonalColorPromptEnhanced:
    def test_create_enhanced_analysis_prompt_includes_sections_and_metadata(self):
        prompt = PersonalColorPrompt()
        metadata = {
            "app_version": "1.2.3",
            "platform": "iOS",
            "timestamp": "2024-01-01T00:00:00Z",
            "user_notes": "テストメモ",
        }

        text = prompt.create_enhanced_analysis_prompt(metadata)

        # Core sections
        assert "年齢・性別推定" in text or "年代・性別" in text
        assert "回答形式" in text
        assert '"person_analysis"' in text

        # Metadata inclusion
        assert "アプリバージョン: 1.2.3" in text
        assert "プラットフォーム: iOS" in text
        assert "撮影時刻: 2024-01-01T00:00:00Z" in text
        assert "ユーザーメモ: テストメモ" in text

    def test_validate_enhanced_response_format_accepts_valid_json(self):
        prompt = PersonalColorPrompt()
        response_text = (
            "Intro text ... {\n"
            "  \"personal_color_type\": \"Spring\",\n"
            "  \"confidence\": 85,\n"
            "  \"explanation\": \"説明\",\n"
            "  \"recommended_colors\": [\"A\", \"B\"],\n"
            "  \"tips\": [\"T1\"],\n"
            "  \"person_analysis\": {\n"
            "    \"age_group\": \"adult\",\n"
            "    \"gender\": \"female\",\n"
            "    \"confidence\": 78\n"
            "  }\n"
            "}\n trailing"
        )

        assert prompt.validate_enhanced_response_format(response_text) is True

    def test_validate_enhanced_response_format_rejects_invalid_age(self):
        prompt = PersonalColorPrompt()
        bad = (
            "{\n"
            "  \"personal_color_type\": \"Spring\",\n"
            "  \"confidence\": 85,\n"
            "  \"explanation\": \"説明\",\n"
            "  \"recommended_colors\": [\"A\"],\n"
            "  \"tips\": [\"T1\"],\n"
            "  \"person_analysis\": {\n"
            "    \"age_group\": \"baby\",\n"
            "    \"gender\": \"female\",\n"
            "    \"confidence\": 78\n"
            "  }\n"
            "}"
        )
        assert prompt.validate_enhanced_response_format(bad) is False

    def test_validate_enhanced_response_format_rejects_missing_person_analysis(self):
        prompt = PersonalColorPrompt()
        no_person = (
            "{\n"
            "  \"personal_color_type\": \"Spring\",\n"
            "  \"confidence\": 85,\n"
            "  \"explanation\": \"説明\",\n"
            "  \"recommended_colors\": [\"A\"],\n"
            "  \"tips\": [\"T1\"]\n"
            "}"
        )
        assert prompt.validate_enhanced_response_format(no_person) is False

