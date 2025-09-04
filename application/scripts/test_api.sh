#!/bin/bash

# API testing script for IoT Sound Detection POC Application

BASE_URL="http://localhost:8000"

echo "Testing IoT Sound Detection POC API..."

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "$BASE_URL/health" | jq '.' || echo "Health check failed"

echo ""

# Test device registration
echo "2. Testing device registration..."
DEVICE_RESPONSE=$(curl -s -X POST "$BASE_URL/devices/" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test-drone-001",
    "device_type": "drone",
    "name": "Test Drone",
    "location": "Test Location"
  }')

echo "$DEVICE_RESPONSE" | jq '.' || echo "Device registration failed"

echo ""

# Test device listing
echo "3. Testing device listing..."
curl -s "$BASE_URL/devices/" | jq '.' || echo "Device listing failed"

echo ""

# Test MQTT status
echo "4. Testing MQTT status..."
curl -s "$BASE_URL/mqtt/status" | jq '.' || echo "MQTT status check failed"

echo ""

# Test analytics health
echo "5. Testing analytics health..."
curl -s "$BASE_URL/analytics/health" | jq '.' || echo "Analytics health check failed"

echo ""

# Test metrics
echo "6. Testing metrics endpoint..."
curl -s "$BASE_URL/metrics/" | head -20 || echo "Metrics endpoint failed"

echo ""
echo "API testing completed!"
