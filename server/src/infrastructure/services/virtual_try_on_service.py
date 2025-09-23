"""Vertex AI Virtual Try-On service integration utilities."""

from __future__ import annotations

import base64
import logging
import time
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional
import json

import httpx
import google.auth
from google.auth.transport.requests import Request
from urllib.parse import quote

from src.infrastructure.exceptions import FashionImageGenerationError

logger = logging.getLogger(__name__)


@dataclass
class VirtualTryOnResult:
    """Result payload returned from the Virtual Try-On API."""

    image_bytes: bytes
    mime_type: str
    model_version: str
    generation_time: float
    raw_response: Dict[str, Any] = field(default_factory=dict)
    parameters_used: Dict[str, Any] = field(default_factory=dict)


class VirtualTryOnError(FashionImageGenerationError):
    """Raised when the Virtual Try-On API request fails."""

    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(message, details)


class _GoogleAccessTokenProvider:
    """Helper responsible for acquiring Google Cloud access tokens."""

    def __init__(self, scopes: Optional[List[str]] = None):
        self.scopes = scopes or ["https://www.googleapis.com/auth/cloud-platform"]
        self._credentials = None

    def get_token(self) -> str:
        """Fetch a valid access token, refreshing credentials when needed."""
        try:
            if self._credentials is None:
                self._credentials, _ = google.auth.default(scopes=self.scopes)

            if not self._credentials.valid or self._credentials.expired or not self._credentials.token:
                logger.debug("Refreshing Google Cloud credentials for Virtual Try-On call")
                self._credentials.refresh(Request())

            if not self._credentials.token:
                raise VirtualTryOnError("Failed to obtain Google Cloud access token")

            return self._credentials.token
        except Exception as exc:  # noqa: BLE001
            raise VirtualTryOnError("Unable to acquire Google Cloud access token") from exc


class VirtualTryOnService:
    """Client wrapper around the Vertex AI Virtual Try-On REST API."""

    def __init__(
        self,
        *,
        project_id: str,
        location: str,
        model_id: str,
        default_product_image_uris: Optional[List[str]] = None,
        sample_count: int = 1,
        add_watermark: bool = True,
        person_generation: str = "allow_adult",
        safety_setting: str = "block_medium_and_above",
        timeout_seconds: int = 60,
        token_provider: Optional[_GoogleAccessTokenProvider] = None,
    ) -> None:
        if not project_id:
            raise ValueError("project_id is required for Virtual Try-On service")
        if not location:
            raise ValueError("location is required for Virtual Try-On service")
        if not model_id:
            raise ValueError("model_id is required for Virtual Try-On service")

        self.project_id = project_id
        self.location = location
        self.model_id = model_id
        self.sample_count = sample_count
        self.add_watermark = add_watermark
        self.person_generation = person_generation
        self.safety_setting = safety_setting
        self.timeout_seconds = timeout_seconds
        self._default_product_image_uris = default_product_image_uris or []
        self._token_provider = token_provider or _GoogleAccessTokenProvider()

        self._endpoint = (
            f"https://{self.location}-aiplatform.googleapis.com/v1/projects/"
            f"{self.project_id}/locations/{self.location}/publishers/google/models/"
            f"{self.model_id}:predict"
        )

    @property
    def default_product_image_uris(self) -> List[str]:
        return list(self._default_product_image_uris)

    async def generate_try_on(
        self,
        *,
        person_image_bytes: Optional[bytes] = None,
        person_image_gcs_uri: Optional[str] = None,
        product_image_uris: Optional[List[str]] = None,
        product_images_base64: Optional[List[str]] = None,
        extra_parameters: Optional[Dict[str, Any]] = None,
    ) -> VirtualTryOnResult:
        """Call the Virtual Try-On API and return the generated image."""

        person_image_payload = self._build_person_image_payload(
            person_image_bytes=person_image_bytes,
            person_image_gcs_uri=person_image_gcs_uri,
        )

        product_payloads = self._build_product_images_payload(
            product_image_uris=product_image_uris,
            product_images_base64=product_images_base64,
        )

        parameters = self._build_parameters(extra_parameters)
        payload = {
            "instances": [
                {
                    "personImage": person_image_payload,
                    "productImages": product_payloads,
                }
            ],
            "parameters": parameters,
        }

        headers = {
            "Authorization": f"Bearer {self._token_provider.get_token()}",
            "Content-Type": "application/json",
        }

        logger.warning(
            "Calling Virtual Try-On API: endpoint=%s, personImage=%s, productImage=%s, parameters=%s",
            self._endpoint,
            json.dumps(person_image_payload, ensure_ascii=False, indent=2)[0:100],
            json.dumps(product_payloads, ensure_ascii=False, indent=2)[0:100],
            json.dumps(parameters, ensure_ascii=False, indent=2)[0:100]
        )

        start_time = time.perf_counter()
        async with httpx.AsyncClient(timeout=self.timeout_seconds) as client:
            response = await client.post(self._endpoint, headers=headers, json=payload)
        elapsed = time.perf_counter() - start_time

        if response.status_code >= 400:
            details = {
                "status_code": response.status_code,
                "body": self._safe_read_response_text(response),
            }
            raise VirtualTryOnError("Virtual Try-On API request failed", details)

        data = response.json()
        predictions = data.get("predictions", [])
        if not predictions:
            raise VirtualTryOnError("Virtual Try-On API returned no predictions", data)

        first_prediction = predictions[0]
        image_b64 = first_prediction.get("bytesBase64Encoded")
        logger.warning("Virtual Try-On API returned image bytes: %s", image_b64[0:1000] if image_b64 else "None")
        if not image_b64:
            raise VirtualTryOnError(
                "Virtual Try-On prediction missing bytesBase64Encoded",
                {"prediction": first_prediction},
            )

        image_bytes = base64.b64decode(image_b64)
        mime_type = first_prediction.get("mimeType", "image/png")

        return VirtualTryOnResult(
            image_bytes=image_bytes,
            mime_type=mime_type,
            model_version=self.model_id,
            generation_time=elapsed,
            raw_response=data,
            parameters_used=parameters,
        )

    def _build_person_image_payload(
        self,
        *,
        person_image_bytes: Optional[bytes],
        person_image_gcs_uri: Optional[str],
    ) -> Dict[str, Any]:
        if person_image_bytes:
            encoded = base64.b64encode(person_image_bytes).decode("utf-8")
            return {"image": {"bytesBase64Encoded": encoded}}

        if person_image_gcs_uri:
            return {"image": {"gcsUri": person_image_gcs_uri}}

        raise VirtualTryOnError("Person image is required for Virtual Try-On")

    def _build_product_images_payload(
        self,
        *,
        product_image_uris: Optional[List[str]],
        product_images_base64: Optional[List[str]],
    ) -> List[Dict[str, Any]]:
        uris = [uri for uri in (product_image_uris or self._default_product_image_uris) if uri]
        base64_images = [img for img in (product_images_base64 or []) if img]

        payloads: List[Dict[str, Any]] = []

        for encoded in base64_images:
            payloads.append({"image": {"bytesBase64Encoded": encoded}})

        logger.debug("Fetching %s product images from GCS for Virtual Try-On", len(uris))
        for uri in uris:
            blob_bytes = self._download_gcs_blob(uri)
            payloads.append({
                "image": {
                    "bytesBase64Encoded": base64.b64encode(blob_bytes).decode("utf-8")
                }
            })

        if not payloads:
            raise VirtualTryOnError(
                "At least one product image must be provided for Virtual Try-On",
                {"default_product_image_uris": self._default_product_image_uris},
            )

        return payloads

    def _build_parameters(self, extra_parameters: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        params: Dict[str, Any] = {
            "addWatermark": True,
            "baseSteps": 32,
            "sampleCount": 1,
        }
        return params

    @staticmethod
    def _safe_read_response_text(response: httpx.Response) -> str:
        try:
            return response.text
        except Exception:  # pragma: no cover
            return ""

    def _download_gcs_blob(self, gcs_uri: str) -> bytes:
        if not gcs_uri.startswith("gs://"):
            raise VirtualTryOnError(
                "Unsupported product image URI provided",
                {"uri": gcs_uri}
            )

        path = gcs_uri[5:]
        if "/" not in path:
            raise VirtualTryOnError(
                "Invalid GCS URI format", {"uri": gcs_uri}
            )

        bucket, object_path = path.split("/", 1)
        encoded_object = quote(object_path, safe="")
        url = (
            f"https://storage.googleapis.com/storage/v1/b/{bucket}/o/{encoded_object}?alt=media"
        )

        headers = {
            "Authorization": f"Bearer {self._token_provider.get_token()}"
        }

        logger.debug("Downloading product image from GCS: %s", gcs_uri)

        with httpx.Client(timeout=self.timeout_seconds) as client:
            response = client.get(url, headers=headers)

        if response.status_code >= 400:
            raise VirtualTryOnError(
                "Failed to download product image from GCS",
                {"uri": gcs_uri, "status_code": response.status_code, "body": response.text}
            )

        return response.content


__all__ = [
    "VirtualTryOnService",
    "VirtualTryOnResult",
    "VirtualTryOnError",
]
