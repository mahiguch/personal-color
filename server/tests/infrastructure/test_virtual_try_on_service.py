import base64
import pytest

from src.infrastructure.services.virtual_try_on_service import (
    VirtualTryOnService,
    VirtualTryOnError,
)


@pytest.mark.skip(reason="Flaky: depends on downloading product image from GCS")
@pytest.mark.asyncio
async def test_generate_try_on_success(mocker):
    mock_creds = mocker.Mock()
    mock_creds.valid = True
    mock_creds.expired = False
    mock_creds.token = "ya29.test-token"
    mocker.patch(
        "src.infrastructure.services.virtual_try_on_service.google.auth.default",
        return_value=(mock_creds, "test-project"),
    )

    mock_response = mocker.Mock()
    mock_response.status_code = 200
    encoded_image = base64.b64encode(b"fake-image-bytes").decode()
    mock_response.json.return_value = {
        "predictions": [
            {
                "mimeType": "image/png",
                "bytesBase64Encoded": encoded_image,
            }
        ]
    }

    mock_client_instance = mocker.AsyncMock()
    mock_client_instance.post = mocker.AsyncMock(return_value=mock_response)

    mock_client_cm = mocker.AsyncMock()
    mock_client_cm.__aenter__.return_value = mock_client_instance
    mocker.patch(
        "src.infrastructure.services.virtual_try_on_service.httpx.AsyncClient",
        return_value=mock_client_cm,
    )

    service = VirtualTryOnService(
        project_id="test-project",
        location="us-central1",
        model_id="virtual-try-on-preview-08-04",
        default_product_image_uris=["gs://bucket/product.png"],
        sample_count=1,
    )

    result = await service.generate_try_on(person_image_bytes=b"person-bytes")

    assert result.image_bytes == b"fake-image-bytes"
    assert result.mime_type == "image/png"
    assert result.model_version == "virtual-try-on-preview-08-04"
    mock_client_instance.post.assert_awaited_once()


@pytest.mark.asyncio
async def test_generate_try_on_requires_product_images(mocker):
    mock_creds = mocker.Mock()
    mock_creds.valid = True
    mock_creds.expired = False
    mock_creds.token = "token"
    mocker.patch(
        "src.infrastructure.services.virtual_try_on_service.google.auth.default",
        return_value=(mock_creds, "test-project"),
    )

    service = VirtualTryOnService(
        project_id="test-project",
        location="us-central1",
        model_id="virtual-try-on-preview-08-04",
        default_product_image_uris=[],
    )

    with pytest.raises(VirtualTryOnError):
        await service.generate_try_on(person_image_bytes=b"person-bytes")
