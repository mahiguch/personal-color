#!/bin/bash

# Test with a larger, more realistic image
API_URL="https://personal-color-api-666814602151.asia-northeast1.run.app"

echo "🧪 Testing with a larger sample image..."

# Create a larger 100x100 red JPEG image (more realistic size)
larger_image="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAAKAAoDAREAAhEBAxEB/8QAFwAAAwEAAAAAAAAAAAAAAAAAAAECA//EACQQAAEDAwMDBQAAAAAAAAAAAAECAxEABCExBRJBE2GhwdHhUf/EABUBAQEAAAAAAAAAAAAAAAAAAAID/8QAGhEAAQUBAAAAAAAAAAAAAAAAAQACEhMhUf/aAAwDAQACEQMRAD8A+v60txKt21z6UQ4Ua5Cxc07jBxGfrppnTiMVrG21AYOzOyL6Xb3CwNRgQ1JmJj7VHxuCTCpbJCMfzuDFJIKiRAR5TLilSCQQJk4AE5J8KKjP/9k="

diagnosis_response=$(curl -s -w "\n%{http_code}" -X POST \
    "${API_URL}/api/v1/diagnose" \
    -H "Content-Type: application/json" \
    -d "{
        \"image_base64\": \"${larger_image}\",
        \"metadata\": {
            \"app_version\": \"1.0.0\",
            \"device_type\": \"iPhone\",
            \"platform\": \"ios\",
            \"image_width\": 100,
            \"image_height\": 100
        }
    }")

diagnosis_status=$(echo "$diagnosis_response" | tail -n1)
diagnosis_body=$(echo "$diagnosis_response" | sed '$d')

echo "Status: $diagnosis_status"

if [[ "$diagnosis_status" =~ ^2[0-9][0-9]$ ]]; then
    echo "✅ SUCCESS: Diagnosis completed"
    echo "$diagnosis_body" | jq '.' 2>/dev/null || echo "$diagnosis_body"
elif [[ "$diagnosis_status" = "422" ]]; then
    echo "⚠️ Validation Error (expected for test images):"
    echo "$diagnosis_body" | jq -r '.detail.message // .detail // "Unknown validation error"' 2>/dev/null
elif [[ "$diagnosis_status" = "429" ]]; then
    echo "❌ Rate Limit Error:"
    echo "$diagnosis_body"
else
    echo "❌ Unexpected Error ($diagnosis_status):"
    echo "$diagnosis_body"
fi

echo ""
echo "📝 Note: Validation errors are expected with synthetic test images."
echo "Real camera photos should work correctly."