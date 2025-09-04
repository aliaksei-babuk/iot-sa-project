#!/bin/bash

# Start script for IoT Sound Detection POC Application

echo "Starting IoT Sound Detection POC Application..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed. Please install docker-compose and try again."
    exit 1
fi

# Create necessary directories
mkdir -p storage/audio storage/models logs

# Set permissions
chmod 755 storage/audio storage/models logs

# Start services
echo "Starting services with docker-compose..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check if services are running
echo "Checking service status..."
docker-compose ps

# Display access information
echo ""
echo "Application is starting up!"
echo "Access the application at:"
echo "  - API Documentation: http://localhost:8000/docs"
echo "  - Health Check: http://localhost:8000/health"
echo "  - Prometheus Metrics: http://localhost:9090"
echo "  - Grafana Dashboard: http://localhost:3000 (admin/admin)"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
