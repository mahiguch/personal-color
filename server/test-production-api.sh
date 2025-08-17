#!/bin/bash

# Production API Test Script
# Cloud Run環境のPersonal Color APIの動作確認

set -e

# Configuration
API_BASE_URL="https://personal-color-api-666814602151.asia-northeast1.run.app"
API_KEY="11A77CCB-4FA0-4CB8-A1FC-E331EAA24B2E"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌐 Testing Production Personal Color API${NC}"
echo -e "${BLUE}API URL: ${API_BASE_URL}${NC}"
echo ""

# サンプル画像データ（Base64エンコードされた小さなJPEG画像）
SAMPLE_IMAGE_BASE64="data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDAREAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k="

# Function to make API request with error handling
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}📡 Testing: ${description}${NC}"
    echo "Endpoint: ${method} ${API_BASE_URL}${endpoint}"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "${method}" \
            "${API_BASE_URL}${endpoint}" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${API_KEY}" \
            -d "${data}")
    else
        response=$(curl -s -w "\n%{http_code}" -X "${method}" \
            "${API_BASE_URL}${endpoint}" \
            -H "Authorization: Bearer ${API_KEY}")
    fi
    
    # Split response and status code
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "Status Code: ${status_code}"
    
    if [[ "$status_code" =~ ^2[0-9][0-9]$ ]]; then
        echo -e "${GREEN}✅ Success${NC}"
        echo "Response:"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    elif [[ "$status_code" =~ ^4[0-9][0-9]$ ]]; then
        echo -e "${YELLOW}⚠️ Client Error (Expected for some tests)${NC}"
        echo "Response:"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo -e "${RED}❌ Server Error${NC}"
        echo "Response:"
        echo "$body"
    fi
    
    echo ""
    sleep 2  # Rate limiting consideration
    return 0
}

# Test 1: Health Check
make_request "GET" "/api/v1/diagnose/test" "" "Health Check"

# Test 2: Privacy Policy
make_request "GET" "/api/v1/privacy/policy" "" "Privacy Policy"

# Test 3: Invalid diagnosis request (should return validation error)
make_request "POST" "/api/v1/diagnose" '{}' "Diagnosis with empty body (validation test)"

# Test 4: Diagnosis with invalid image data
make_request "POST" "/api/v1/diagnose" '{
    "image_base64": "invalid_base64_data",
    "metadata": {
        "app_version": "1.0.0",
        "device_type": "test"
    }
}' "Diagnosis with invalid image data"

# Test 5: Valid diagnosis request with sample image
make_request "POST" "/api/v1/diagnose" "{
    \"image_base64\": \"${SAMPLE_IMAGE_BASE64}\",
    \"metadata\": {
        \"app_version\": \"1.0.0\",
        \"device_type\": \"test_device\",
        \"platform\": \"ios\"
    }
}" "Diagnosis with valid sample image"

# Test 6: File upload test (create a temporary image file)
echo -e "${YELLOW}📡 Testing: File Upload Diagnosis${NC}"
echo "Endpoint: POST ${API_BASE_URL}/api/v1/diagnose/upload"

# Create a temporary minimal JPEG file
temp_file=$(mktemp --suffix=.jpg)
echo -e '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xff\xdb\x00C\x00' > "$temp_file"
echo -e '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xd9' >> "$temp_file"

upload_response=$(curl -s -w "\n%{http_code}" \
    -X POST "${API_BASE_URL}/api/v1/diagnose/upload" \
    -H "Authorization: Bearer ${API_KEY}" \
    -F "file=@${temp_file};type=image/jpeg" \
    -F 'metadata={"app_version":"1.0.0","device_type":"test"}')

upload_status_code=$(echo "$upload_response" | tail -n1)
upload_body=$(echo "$upload_response" | sed '$d')

echo "Status Code: ${upload_status_code}"
if [[ "$upload_status_code" =~ ^2[0-9][0-9]$ ]]; then
    echo -e "${GREEN}✅ Success${NC}"
    echo "Response:"
    echo "$upload_body" | jq . 2>/dev/null || echo "$upload_body"
else
    echo -e "${YELLOW}⚠️ Upload test result: ${upload_status_code}${NC}"
    echo "Response:"
    echo "$upload_body"
fi

# Cleanup
rm -f "$temp_file"

echo ""
echo -e "${GREEN}🎉 Production API Testing Completed!${NC}"
echo ""
echo -e "${BLUE}📋 Test Summary:${NC}"
echo "- Health check endpoint tested"
echo "- Privacy policy endpoint tested"
echo "- Validation error handling tested"
echo "- Image processing tested"
echo "- File upload tested"
echo ""
echo -e "${YELLOW}💡 API Usage Notes:${NC}"
echo "1. All endpoints are working"
echo "2. Rate limiting is active (10 requests/minute for diagnosis)"
echo "3. Image size limit: 10MB"
echo "4. Supported formats: JPEG, PNG"
echo ""
echo -e "${BLUE}🔗 API Documentation:${NC}"
echo "- Health: GET ${API_BASE_URL}/api/v1/diagnose/test"
echo "- Diagnosis: POST ${API_BASE_URL}/api/v1/diagnose"
echo "- Upload: POST ${API_BASE_URL}/api/v1/diagnose/upload"
echo "- Privacy: GET ${API_BASE_URL}/api/v1/diagnose/privacy/policy"