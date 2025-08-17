#!/bin/bash

# Quick Production API Test
# 基本的な動作確認のみ

API_URL="https://personal-color-api-666814602151.asia-northeast1.run.app"

echo "🚀 Quick API Test"
echo "Testing: $API_URL"
echo ""

# 1. Health Check
echo "1. Health Check..."
response=$(curl -s "${API_URL}/api/v1/diagnose/test")
if echo "$response" | grep -q "status"; then
    echo "✅ Health Check: OK"
    echo "   Response: $(echo "$response" | jq -r '.status // .message' 2>/dev/null || echo "API responding")"
else
    echo "❌ Health Check: Failed"
    echo "   Response: $response"
fi

echo ""

# 2. Privacy Policy
echo "2. Privacy Policy..."
privacy_status=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/api/v1/privacy/policy")
if [ "$privacy_status" = "200" ]; then
    echo "✅ Privacy Policy: OK"
else
    echo "⚠️ Privacy Policy: Status $privacy_status"
fi

echo ""

# 3. Validation Test
echo "3. Validation Test (empty request)..."
validation_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "${API_URL}/api/v1/diagnose" \
    -H "Content-Type: application/json" \
    -d '{}')

if [ "$validation_status" = "422" ]; then
    echo "✅ Validation: Working (422 as expected)"
elif [ "$validation_status" = "400" ]; then
    echo "✅ Validation: Working (400 as expected)"
else
    echo "⚠️ Validation: Unexpected status $validation_status"
fi

echo ""

# 4. Sample Diagnosis
echo "4. Sample Diagnosis Request..."
# Use real portrait image for testing
if [ -f "test_images/selfy-yellow-base.png" ]; then
    echo "   Using real portrait image: test_images/selfy-yellow-base.png"
    sample_image="data:image/png;base64,$(base64 -i test_images/selfy-yellow-base.png | tr -d '\n')"
else
    echo "   Warning: test_images/selfy-yellow-base.png not found, using minimal test image"
    sample_image="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k="
fi

diagnosis_response=$(curl -s -w "\n%{http_code}" -X POST \
    "${API_URL}/api/v1/diagnose" \
    -H "Content-Type: application/json" \
    -d "{
        \"image_base64\": \"${sample_image}\",
        \"metadata\": {
            \"app_version\": \"1.0.0\",
            \"device_type\": \"iPhone\",
            \"platform\": \"ios\",
            \"image_source\": \"camera\",
            \"capture_mode\": \"portrait\"
        }
    }")

diagnosis_status=$(echo "$diagnosis_response" | tail -n1)
diagnosis_body=$(echo "$diagnosis_response" | sed '$d')

if [[ "$diagnosis_status" =~ ^2[0-9][0-9]$ ]]; then
    echo "✅ Diagnosis: SUCCESS"
    # Try to extract result
    result=$(echo "$diagnosis_body" | jq -r '.result.personal_color_type // "N/A"' 2>/dev/null)
    echo "   Result: $result"
elif [[ "$diagnosis_status" =~ ^4[0-9][0-9]$ ]]; then
    echo "⚠️ Diagnosis: Client Error ($diagnosis_status)"
    error_msg=$(echo "$diagnosis_body" | jq -r '.detail.message // .detail // "Unknown error"' 2>/dev/null)
    echo "   Error: $error_msg"
else
    echo "❌ Diagnosis: Server Error ($diagnosis_status)"
fi

echo ""
echo "🎯 Quick Test Complete!"
echo ""
echo "📝 Summary:"
echo "   API URL: $API_URL"
echo "   All core endpoints tested"
echo "   Ready for client integration"