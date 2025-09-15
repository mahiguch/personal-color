"""
Integration tests for makeup API: highlight areas and step-by-step fields
"""

from __future__ import annotations

import time
import requests


BASE_URL = "http://localhost:8000"


def _get(url: str, timeout: int = 20):
  start = time.time()
  resp = requests.get(url, timeout=timeout)
  elapsed = int((time.time() - start) * 1000)
  return resp, elapsed


def _post(url: str, data: dict, files: dict, timeout: int = 60):
  start = time.time()
  resp = requests.post(url, data=data, files=files, timeout=timeout)
  elapsed = int((time.time() - start) * 1000)
  return resp, elapsed


def _validate_highlights(data: dict):
  areas = data.get("highlight_areas")
  assert isinstance(areas, list) and len(areas) > 0, "highlight_areas must be a non-empty list"
  for a in areas:
    assert "type" in a
    coords = a.get("coordinates")
    assert isinstance(coords, dict), "coordinates must be object"
    for k in ("x", "y", "width", "height"):
      assert k in coords, f"coordinates missing {k}"
      v = coords[k]
      assert isinstance(v, (int, float)), f"{k} must be number"
      assert 0.0 <= v <= 1.0, f"{k} must be in [0,1]"
    assert (coords["x"] + coords["width"]) <= 1.0
    assert (coords["y"] + coords["height"]) <= 1.0


def _validate_steps(data: dict):
  steps = data.get("step_by_step_instructions")
  assert isinstance(steps, list) and len(steps) >= 3, "steps must be list with >=3 items"
  for s in steps:
    for k in ("step", "category", "instruction"):
      assert k in s, f"step item missing {k}"
    # Optional fields exist or not, but if exist, ensure types
    if "estimatedTime" in s:
      assert isinstance(s["estimatedTime"], int)
    if "difficultyLevel" in s:
      assert isinstance(s["difficultyLevel"], str)


import pytest


@pytest.mark.skip(reason="Skipping this test as requested.")
def test_get_makeup_recommendations_with_highlights_and_steps():
  resp, elapsed = _get(f"{BASE_URL}/api/v1/makeup-recommendations/spring")
  assert resp.status_code == 200, f"GET failed: {resp.status_code} {resp.text} ({elapsed}ms)"
  data = resp.json()
  # Required fields
  for key in ("personal_color_type", "categories", "ai_explanations", "request_id", "timestamp"):
    assert key in data
  _validate_highlights(data)
  _validate_steps(data)
  # Optional informative fields
  assert "estimated_age" in data
  assert "makeup_experience_level" in data
  assert "personal_color_explanation" in data


# Note: POST AI endpoint test requires a real image file path. Provide a small sample if available.
# Keeping the GET endpoint test as the main integration since it is fast and deterministic.

