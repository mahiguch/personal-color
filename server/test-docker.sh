#!/bin/bash

# Docker環境でのテストスクリプト
# Cloud Runデプロイ前の動作確認用

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Testing Personal Color API with Docker${NC}"

# Function to test service
test_service() {
    local service_name=$1
    local port=$2
    local wait_time=${3:-60}
    
    echo -e "${YELLOW}📋 Testing ${service_name} on port ${port}...${NC}"
    
    # Wait for service to be ready
    echo "Waiting ${wait_time}s for service to start..."
    sleep ${wait_time}
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -f "http://localhost:${port}/api/v1/diagnose/test" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Health check passed${NC}"
    else
        echo -e "${RED}❌ Health check failed${NC}"
        echo "Checking logs..."
        docker-compose logs ${service_name}
        return 1
    fi
    
    # Test API structure
    echo "Testing API response structure..."
    response=$(curl -s "http://localhost:${port}/api/v1/diagnose/test")
    if echo "$response" | grep -q "status"; then
        echo -e "${GREEN}✅ API structure test passed${NC}"
        echo "Response: $response"
    else
        echo -e "${RED}❌ API structure test failed${NC}"
        echo "Response: $response"
        return 1
    fi
    
    # Test diagnosis endpoint (should return validation error for empty request)
    echo "Testing diagnosis endpoint validation..."
    status_code=$(curl -X POST "http://localhost:${port}/api/v1/diagnose" \
         -H "Content-Type: application/json" \
         -d '{}' \
         -w "%{http_code}" -o /dev/null -s)
    
    if [ "$status_code" = "422" ]; then
        echo -e "${GREEN}✅ Diagnosis endpoint validation working${NC}"
    else
        echo -e "${YELLOW}⚠️ Diagnosis endpoint returned status: $status_code${NC}"
    fi
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    docker-compose down --volumes --remove-orphans
}

# Set trap for cleanup
trap cleanup EXIT

# Test production build
echo -e "${BLUE}Testing production build...${NC}"
docker-compose up --build -d personal-color-api

# Wait and test
test_service "personal-color-api" "8000" 60

# Show logs if needed
echo -e "${BLUE}📋 Recent logs:${NC}"
docker-compose logs --tail=20 personal-color-api

# Test with development build (optional)
read -p "Do you want to test development build as well? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Testing development build...${NC}"
    docker-compose --profile dev up --build -d personal-color-api-dev
    test_service "personal-color-api-dev" "8001" 30
    docker-compose logs --tail=20 personal-color-api-dev
fi

echo -e "${GREEN}🎉 Docker tests completed!${NC}"
echo ""
echo -e "${BLUE}📋 Docker Test Summary:${NC}"
echo "- Production build tested on port 8000"
echo "- Health check endpoint working"
echo "- API response structure validated"
echo ""
echo -e "${YELLOW}💡 If all tests passed, the issue is likely Cloud Run specific:${NC}"
echo "1. Check Cloud Run resource limits"
echo "2. Verify service account permissions"
echo "3. Check Vertex AI API access from Cloud Run"
echo "4. Review Cloud Run timeout settings"