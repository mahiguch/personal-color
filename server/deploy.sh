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
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Set up GCP project and services
setup_gcp() {
    echo -e "${YELLOW}🔧 Setting up GCP project and services...${NC}"
    
    # Set the project
    gcloud config set project ${PROJECT_ID}
    
    # Enable required APIs
    echo "Enabling required APIs..."
    gcloud services enable \
        cloudbuild.googleapis.com \
        run.googleapis.com \
        containerregistry.googleapis.com \
        artifactregistry.googleapis.com \
        aiplatform.googleapis.com \
        monitoring.googleapis.com \
        logging.googleapis.com \
        cloudprofiler.googleapis.com \
        cloudtrace.googleapis.com
    
    echo -e "${GREEN}✅ GCP setup completed${NC}"
}

# Create service account and permissions
setup_service_account() {
    echo -e "${YELLOW}👤 Setting up service account...${NC}"
    
    SA_NAME="personal-color-api-sa"
    SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Create service account if it doesn't exist
    if ! gcloud iam service-accounts describe ${SA_EMAIL} &> /dev/null; then
        gcloud iam service-accounts create ${SA_NAME} \
            --display-name="Personal Color API Service Account" \
            --description="Service account for Personal Color API"
    fi
    
    # Grant necessary permissions
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/aiplatform.user"
    
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/monitoring.metricWriter"
    
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/logging.logWriter"
    
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/cloudtrace.agent"
    
    echo -e "${GREEN}✅ Service account setup completed${NC}"
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
    
    # Replace placeholders in service configuration
    sed "s/PROJECT_ID/${PROJECT_ID}/g" cloudrun-service.yaml > cloudrun-service-deploy.yaml
    
    # Deploy the service
    gcloud run services replace cloudrun-service-deploy.yaml \
        --platform=managed \
        --region=${REGION}
    
    # Ensure the service allows unauthenticated access (for public API)
    gcloud run services add-iam-policy-binding ${SERVICE_NAME} \
        --member="allUsers" \
        --role="roles/run.invoker" \
        --region=${REGION}
    
    # Get the service URL
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
        --platform=managed \
        --region=${REGION} \
        --format="value(status.url)")
    
    echo -e "${GREEN}✅ Cloud Run deployment completed${NC}"
    echo -e "${BLUE}Service URL: ${SERVICE_URL}${NC}"
    
    # Clean up temporary file
    rm -f cloudrun-service-deploy.yaml
}

# Setup monitoring and alerting
setup_monitoring() {
    echo -e "${YELLOW}📊 Setting up monitoring and alerting...${NC}"
    
    # Create notification channel (email)
    # Note: This requires manual setup in the console for the first time
    echo "Monitoring setup requires manual configuration in Google Cloud Console:"
    echo "1. Go to Monitoring > Alerting > Notification Channels"
    echo "2. Create email notification channel"
    echo "3. Set up alerting policies for:"
    echo "   - High error rate (>5%)"
    echo "   - High latency (>10s)"
    echo "   - High memory usage (>80%)"
    echo "   - Service down"
    
    echo -e "${GREEN}✅ Monitoring setup instructions provided${NC}"
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

# Main deployment flow
main() {
    check_prerequisites
    setup_gcp
    setup_service_account
    build_and_push
    deploy_cloudrun
    setup_monitoring
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
    echo "2. Configure custom domain (if needed)"
    echo "3. Set up monitoring alerts in Google Cloud Console"
    echo "4. Test the complete application flow"
    echo ""
    echo -e "${YELLOW}📊 Monitoring Links:${NC}"
    echo "Cloud Run Console: https://console.cloud.google.com/run/detail/${REGION}/${SERVICE_NAME}/metrics?project=${PROJECT_ID}"
    echo "Logs: https://console.cloud.google.com/logs/query?project=${PROJECT_ID}"
    echo "Monitoring: https://console.cloud.google.com/monitoring?project=${PROJECT_ID}"
}

# Run main function
main "$@"