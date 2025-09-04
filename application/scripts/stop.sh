#!/bin/bash

# Stop script for IoT Sound Detection POC Application

echo "Stopping IoT Sound Detection POC Application..."

# Stop services
docker-compose down

echo "Application stopped successfully!"
echo "To remove volumes and data: docker-compose down -v"
