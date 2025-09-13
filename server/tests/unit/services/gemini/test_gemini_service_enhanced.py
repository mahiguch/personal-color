import pytest
from unittest.mock import patch, MagicMock

import src.services.gemini_service as gemini_module
from src.services.gemini_service import get_gemini_service


@pytest.mark.asyncio
async def test_analyze_personal_color_with_demographics_success():
    # Reset singleton
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()

    # Patch the sync enhanced vision call to return a valid JSON text
    valid_text = (
        "{\n"
        "  \"personal_color_type\": \"Spring\",\n"
        "  \"confidence\": 88,\n"
        "  \"explanation\": \"説明\",\n"
        "  \"recommended_colors\": [\"A\"],\n"
        "  \"tips\": [\"T1\"],\n"
        "  \"person_analysis\": {\n"
        "    \"age_group\": \"adult\",\n"
        "    \"gender\": \"female\",\n"
        "    \"confidence\": 80\n"
        "  }\n"
        "}"
    )

    with patch.object(
        service, "_call_gemini_vision_sync_enhanced", return_value=MagicMock(text=valid_text)
    ):
        # Ensure client exists
        service.client = MagicMock()
        result = await service.analyze_personal_color_with_demographics("dGVzdA==", {})

    assert result.success is True
    assert result.response is not None
    assert result.response.is_fallback is False


@pytest.mark.asyncio
async def test_analyze_personal_color_with_demographics_fallback_when_no_client():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    # Simulate client unavailable
    service.client = None

    result = await service.analyze_personal_color_with_demographics("dGVzdA==", {})
    assert result.success is True
    assert result.response is not None
    assert result.response.is_fallback is True
    assert "person_analysis" in result.response.content


@pytest.mark.asyncio
async def test_analyze_personal_color_with_demographics_validation_failure_fallback():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    # Provide a client to avoid early fallback
    service.client = MagicMock()

    invalid_text = "not-json"
    # Limit retries for speed
    service._max_retries = 1

    with patch.object(
        service, "_call_gemini_vision_sync_enhanced", return_value=MagicMock(text=invalid_text)
    ):
        result = await service.analyze_personal_color_with_demographics("dGVzdA==", {})

    # Should fallback due to validation failure
    assert result.success is True
    assert result.response is not None
    assert result.response.is_fallback is True


def test_parse_enhanced_response_success():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    valid_text = (
        "{\n"
        "  \"personal_color_type\": \"Spring\",\n"
        "  \"confidence\": 88,\n"
        "  \"explanation\": \"説明\",\n"
        "  \"recommended_colors\": [\"A\"],\n"
        "  \"tips\": [\"T1\"],\n"
        "  \"person_analysis\": {\n"
        "    \"age_group\": \"adult\",\n"
        "    \"gender\": \"female\",\n"
        "    \"confidence\": 80\n"
        "  }\n"
        "}"
    )
    parsed = service._parse_enhanced_response(valid_text)
    assert parsed["personal_color_type"] == "Spring"
    assert parsed["person_analysis"]["gender"] == "female"


def test_parse_enhanced_response_failure():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    with pytest.raises(ValueError):
        service._parse_enhanced_response("not-json")


def test_get_adaptive_tips_varies_by_age_and_gender():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    tips_child = service._get_adaptive_tips("child", "unknown")
    assert any("お家の人" in t for t in tips_child)
    tips_adult_male = service._get_adaptive_tips("adult", "male")
    assert any("実用的" in t for t in tips_adult_male)
