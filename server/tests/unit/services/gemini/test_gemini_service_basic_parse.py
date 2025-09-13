import pytest

import src.services.gemini_service as gemini_module
from src.services.gemini_service import get_gemini_service


def test_parse_basic_response_success():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    text = (
        "{\n"
        "  \"personal_color_type\": \"Summer\",\n"
        "  \"confidence\": 77,\n"
        "  \"explanation\": \"説明\",\n"
        "  \"recommended_colors\": [\"X\"],\n"
        "  \"tips\": [\"Tip\"]\n"
        "}"
    )
    parsed = service._parse_basic_response(text)
    assert parsed["personal_color_type"] == "Summer"
    assert parsed["confidence"] == 77


def test_parse_basic_response_failure():
    gemini_module._gemini_service_instance = None
    service = get_gemini_service()
    with pytest.raises(ValueError):
        service._parse_basic_response("no-json here")

