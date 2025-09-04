#!/bin/bash

# Personal Color API Deployment Script for Google Cloud Platform
# Usage: ./deploy.sh [environment] [project-id]

set -e

# Configuration
ENVIRONMENT=${1:-production}
PROJECT_ID=${2:-"personal-color-469007"}
REGION="asia-northeast1"
SERVICE_NAME="personal-color-api"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting deployment for Personal Color API${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Project ID: ${PROJECT_ID}${NC}"
echo -e "${BLUE}Region: ${REGION}${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}📋 Checking prerequisites...${NC}"
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}❌ Google Cloud CLI is not installed${NC}"
        exit 1
    fi
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        exit 1
    fi
    
    # Check if logged into gcloud
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
        echo -e "${RED}❌ Not logged into Google Cloud${NC}"
        echo "Please run: gcloud auth login"
        exit 1
    fi
    
    # Set the project
    gcloud config set project ${PROJECT_ID}
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Build and push Docker image
build_and_push() {
    echo -e "${YELLOW}🐳 Building and pushing Docker image...${NC}"
    
    # Build the image
    echo "Building Docker image..."
    docker build --target production -t ${IMAGE_NAME}:latest .
    
    # Tag with version
    VERSION=$(date +%Y%m%d-%H%M%S)
    docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${VERSION}
    
    # Configure Docker for GCR
    gcloud auth configure-docker
    
    # Push images
    echo "Pushing Docker images..."
    docker push ${IMAGE_NAME}:latest
    docker push ${IMAGE_NAME}:${VERSION}
    
    echo -e "${GREEN}✅ Docker image built and pushed${NC}"
    echo -e "${BLUE}Image: ${IMAGE_NAME}:latest${NC}"
    echo -e "${BLUE}Version: ${IMAGE_NAME}:${VERSION}${NC}"
}

# Deploy to Cloud Run
deploy_cloudrun() {
    echo -e "${YELLOW}☁️ Deploying to Cloud Run...${NC}"
    
    # Deploy the service using gcloud run deploy
    gcloud run deploy ${SERVICE_NAME} \
        --image=${IMAGE_NAME}:latest \
        --platform=managed \
        --region=${REGION} \
        --allow-unauthenticated \
        --port=8080 \
        --memory=2Gi \
        --cpu=1000m \
        --timeout=60s \
        --max-instances=10 \
        --service-account="personal-color-api-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
        --set-env-vars="ENVIRONMENT=${ENVIRONMENT}"
    
    # Get the service URL
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
        --platform=managed \
        --region=${REGION} \
        --format="value(status.url)")
    
    echo -e "${GREEN}✅ Cloud Run deployment completed${NC}"
    echo -e "${BLUE}Service URL: ${SERVICE_URL}${NC}"
}

# Run health check
health_check() {
    echo -e "${YELLOW}🏥 Running health check...${NC}"
    
    # Get service URL
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
        --platform=managed \
        --region=${REGION} \
        --format="value(status.url)")
    
    # Wait for service to be ready
    echo "Waiting for service to be ready..."
    sleep 30
    
    # Test health endpoint
    if curl -f "${SERVICE_URL}/api/v1/diagnose/test" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Health check passed${NC}"
    else
        echo -e "${RED}❌ Health check failed${NC}"
        exit 1
    fi
    
    # Test API endpoints
    echo "Testing API endpoints..."
    
    # Test diagnosis endpoint (should return 422 for empty request)
    if curl -X POST "${SERVICE_URL}/api/v1/diagnose" \
         -H "Content-Type: application/json" \
         -d '{}' \
         -w "%{http_code}" -o /dev/null -s | grep -q "422"; then
        echo -e "${GREEN}✅ Diagnosis endpoint responding correctly${NC}"
    else
        echo -e "${YELLOW}⚠️ Diagnosis endpoint test inconclusive${NC}"
    fi
}

# Pre-deployment checks
run_pre_deploy_checks() {
    echo -e "${YELLOW}🔍 Running pre-deployment checks...${NC}"
    
    if [ -f "./scripts/pre_deploy_check.sh" ]; then
        if ./scripts/pre_deploy_check.sh; then
            echo -e "${GREEN}✅ Pre-deployment checks passed${NC}"
        else
            echo -e "${RED}❌ Pre-deployment checks failed${NC}"
            echo "Please fix the issues before deploying"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️ Pre-deployment check script not found, skipping${NC}"
    fi
}

# Main deployment flow
main() {
    run_pre_deploy_checks
    check_prerequisites
    build_and_push
    deploy_cloudrun
    health_check
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Deployment Summary:${NC}"
    echo -e "${BLUE}Project ID: ${PROJECT_ID}${NC}"
    echo -e "${BLUE}Service Name: ${SERVICE_NAME}${NC}"
    echo -e "${BLUE}Region: ${REGION}${NC}"
    
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
        --platform=managed \
        --region=${REGION} \
        --format="value(status.url)")
    
    echo -e "${BLUE}Service URL: ${SERVICE_URL}${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo "1. Update Flutter app API configuration with the new URL"
    echo "2. Test the complete application flow"
    echo ""
    echo -e "${YELLOW}📊 Monitoring Links:${NC}"
    echo "Cloud Run Console: https://console.cloud.google.com/run/detail/${REGION}/${SERVICE_NAME}/metrics?project=${PROJECT_ID}"
    echo "Logs: https://console.cloud.google.com/logs/query?project=${PROJECT_ID}"
}

# Run main function
main "$@"