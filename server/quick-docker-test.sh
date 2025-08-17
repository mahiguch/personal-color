#!/bin/bash

# 簡易Dockerテスト - 問題の早期発見用

set -e

echo "🐳 Quick Docker Test"

# Build and start
echo "Building and starting container..."
docker-compose up --build -d personal-color-api

# Wait a bit
echo "Waiting 30 seconds for startup..."
sleep 30

# Check if container is running
if docker-compose ps personal-color-api | grep -q "Up"; then
    echo "✅ Container is running"
else
    echo "❌ Container failed to start"
    echo "Container status:"
    docker-compose ps personal-color-api
    echo "Logs:"
    docker-compose logs personal-color-api
    exit 1
fi

# Quick health check
echo "Testing health endpoint..."
if curl -f "http://localhost:8000/api/v1/diagnose/test" 2>/dev/null; then
    echo "✅ Health check passed!"
    echo "Response:"
    curl -s "http://localhost:8000/api/v1/diagnose/test" | jq . 2>/dev/null || curl -s "http://localhost:8000/api/v1/diagnose/test"
else
    echo "❌ Health check failed"
    echo "Container logs:"
    docker-compose logs --tail=50 personal-color-api
fi

# Cleanup
docker-compose down

echo "Quick test completed."