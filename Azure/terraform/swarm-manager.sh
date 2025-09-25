#!/bin/bash
# IoT Sound Analytics Swarm Manager
# Управление роем IoT агентов для звуковой аналитики

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}"
SWARM_ID="sound-analytics-swarm"
AGENT_VERSION="2.0.0"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  IoT Sound Analytics Swarm Manager${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure CLI"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Deploy swarm infrastructure
deploy_swarm_infrastructure() {
    print_info "Deploying swarm infrastructure..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        print_info "Initializing Terraform..."
        terraform init
    fi
    
    # Plan deployment
    print_info "Planning deployment..."
    terraform plan -out=swarm.tfplan
    
    # Apply deployment
    print_info "Applying deployment..."
    terraform apply swarm.tfplan
    
    print_success "Swarm infrastructure deployed"
}

# Get IoT Hub connection string
get_iot_hub_connection_string() {
    print_info "Getting IoT Hub connection string..."
    
    cd "$TERRAFORM_DIR"
    
    # Get the connection string from Terraform output
    IOT_HUB_CONNECTION_STRING=$(terraform output -raw iot_hub_connection_string 2>/dev/null || echo "")
    
    if [ -z "$IOT_HUB_CONNECTION_STRING" ]; then
        print_error "Failed to get IoT Hub connection string"
        exit 1
    fi
    
    print_success "IoT Hub connection string retrieved"
    echo "$IOT_HUB_CONNECTION_STRING"
}

# Register swarm agent device
register_swarm_agent() {
    local agent_id="$1"
    local location="$2"
    
    if [ -z "$agent_id" ] || [ -z "$location" ]; then
        print_error "Agent ID and location are required"
        echo "Usage: $0 register-agent <agent-id> <location>"
        exit 1
    fi
    
    print_info "Registering swarm agent: $agent_id in $location"
    
    local iot_hub_connection_string=$(get_iot_hub_connection_string)
    
    # Extract IoT Hub name from connection string
    local iot_hub_name=$(echo "$iot_hub_connection_string" | sed -n 's/.*HostName=\([^.]*\).*/\1/p')
    
    # Register device
    az iot hub device-identity create \
        --hub-name "$iot_hub_name" \
        --device-id "$agent_id" \
        --edge-enabled false \
        --tags "swarmType=sound-agent,location=$location,agentVersion=$AGENT_VERSION,status=inactive" \
        --output none
    
    # Get device connection string
    local device_connection_string=$(az iot hub device-identity connection-string show \
        --hub-name "$iot_hub_name" \
        --device-id "$agent_id" \
        --query connectionString -o tsv)
    
    print_success "Agent $agent_id registered successfully"
    print_info "Device connection string: $device_connection_string"
    
    # Save connection string to file
    echo "$device_connection_string" > "agent-${agent_id}-connection.txt"
    print_info "Connection string saved to agent-${agent_id}-connection.txt"
}

# Deploy agent to device
deploy_agent_to_device() {
    local agent_id="$1"
    local device_ip="$2"
    local ssh_user="$3"
    
    if [ -z "$agent_id" ] || [ -z "$device_ip" ] || [ -z "$ssh_user" ]; then
        print_error "Agent ID, device IP, and SSH user are required"
        echo "Usage: $0 deploy-agent <agent-id> <device-ip> <ssh-user>"
        exit 1
    fi
    
    print_info "Deploying agent $agent_id to $device_ip"
    
    # Check if connection string file exists
    if [ ! -f "agent-${agent_id}-connection.txt" ]; then
        print_error "Connection string file not found. Please register the agent first."
        exit 1
    fi
    
    local device_connection_string=$(cat "agent-${agent_id}-connection.txt")
    
    # Create deployment script with connection string
    cat > "deploy-${agent_id}.sh" << EOF
#!/bin/bash
# Agent deployment script for $agent_id

set -e

# Configuration
SWARM_ID="$SWARM_ID"
AGENT_ID="$agent_id"
AGENT_VERSION="$AGENT_VERSION"
DEVICE_CONNECTION_STRING="$device_connection_string"

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip alsa-utils sox

# Install Python packages
pip3 install azure-iot-device azure-iot-hub-client librosa scikit-learn numpy soundfile psutil

# Create agent directory
sudo mkdir -p /opt/iot-sound-agent
cd /opt/iot-sound-agent

# Create agent configuration
cat > agent_config.json << 'EOL'
{
  "swarmId": "$SWARM_ID",
  "agentId": "$AGENT_ID",
  "version": "$AGENT_VERSION",
  "iotHubConnectionString": "$DEVICE_CONNECTION_STRING",
  "audioSettings": {
    "sampleRate": 22050,
    "duration": 2.0,
    "channels": 1,
    "format": "wav"
  },
  "mlSettings": {
    "modelVersion": "2.0.0",
    "confidenceThreshold": 0.7,
    "enableRealTimeProcessing": true
  },
  "networkSettings": {
    "retryAttempts": 3,
    "timeoutSeconds": 30,
    "enableCompression": true
  }
}
EOL

# Download agent code (simplified version)
cat > agent.py << 'EOL'
#!/usr/bin/env python3
import json
import time
import logging
import asyncio
import numpy as np
from datetime import datetime
from azure.iot.device import IoTHubDeviceClient, Message

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SwarmAgent:
    def __init__(self, config_path="/opt/iot-sound-agent/agent_config.json"):
        with open(config_path, 'r') as f:
            self.config = json.load(f)
        
        self.client = IoTHubDeviceClient.create_from_connection_string(
            self.config['iotHubConnectionString']
        )
        self.client.connect()
        
        self.swarm_id = self.config['swarmId']
        self.agent_id = self.config['agentId']
        logger.info(f"Swarm Agent {self.agent_id} initialized")
    
    async def run(self):
        logger.info("Starting swarm agent...")
        while True:
            try:
                # Mock audio processing
                message_data = {
                    'agentId': self.agent_id,
                    'swarmId': self.swarm_id,
                    'timestamp': datetime.utcnow().isoformat(),
                    'status': 'active'
                }
                
                message = Message(json.dumps(message_data))
                await self.client.send_message(message)
                logger.info("Telemetry sent")
                
                await asyncio.sleep(30)
            except Exception as e:
                logger.error(f"Error: {e}")
                await asyncio.sleep(5)

if __name__ == "__main__":
    agent = SwarmAgent()
    asyncio.run(agent.run())
EOL

# Create systemd service
sudo tee /etc/systemd/system/iot-sound-agent.service > /dev/null << 'EOL'
[Unit]
Description=IoT Sound Analytics Agent
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/iot-sound-agent
ExecStart=/usr/bin/python3 /opt/iot-sound-agent/agent.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable iot-sound-agent
sudo systemctl start iot-sound-agent

echo "Swarm agent deployed successfully!"
echo "Agent ID: $AGENT_ID"
echo "Swarm ID: $SWARM_ID"
echo "Status: \$(sudo systemctl is-active iot-sound-agent)"
EOF
    
    # Copy and execute deployment script
    scp "deploy-${agent_id}.sh" "${ssh_user}@${device_ip}:/tmp/"
    ssh "${ssh_user}@${device_ip}" "chmod +x /tmp/deploy-${agent_id}.sh && sudo /tmp/deploy-${agent_id}.sh"
    
    # Clean up
    rm "deploy-${agent_id}.sh"
    
    print_success "Agent $agent_id deployed to $device_ip"
}

# List swarm agents
list_swarm_agents() {
    print_info "Listing swarm agents..."
    
    local iot_hub_connection_string=$(get_iot_hub_connection_string)
    local iot_hub_name=$(echo "$iot_hub_connection_string" | sed -n 's/.*HostName=\([^.]*\).*/\1/p')
    
    # List devices with swarm tags
    az iot hub device-identity list \
        --hub-name "$iot_hub_name" \
        --query "[?tags.swarmType == 'sound-agent'].{DeviceId:deviceId, Status:tags.status, Location:tags.location, Version:tags.agentVersion}" \
        --output table
    
    print_success "Swarm agents listed"
}

# Monitor swarm status
monitor_swarm() {
    print_info "Monitoring swarm status..."
    
    local iot_hub_connection_string=$(get_iot_hub_connection_string)
    local iot_hub_name=$(echo "$iot_hub_connection_string" | sed -n 's/.*HostName=\([^.]*\).*/\1/p')
    
    # Monitor device telemetry
    print_info "Monitoring device telemetry (Press Ctrl+C to stop)..."
    az iot hub monitor-events \
        --hub-name "$iot_hub_name" \
        --device-id "*" \
        --timeout 0
}

# Update swarm configuration
update_swarm_config() {
    print_info "Updating swarm configuration..."
    
    cd "$TERRAFORM_DIR"
    
    # Apply configuration updates
    terraform apply -auto-approve
    
    print_success "Swarm configuration updated"
}

# Remove swarm agent
remove_swarm_agent() {
    local agent_id="$1"
    
    if [ -z "$agent_id" ]; then
        print_error "Agent ID is required"
        echo "Usage: $0 remove-agent <agent-id>"
        exit 1
    fi
    
    print_info "Removing swarm agent: $agent_id"
    
    local iot_hub_connection_string=$(get_iot_hub_connection_string)
    local iot_hub_name=$(echo "$iot_hub_connection_string" | sed -n 's/.*HostName=\([^.]*\).*/\1/p')
    
    # Remove device
    az iot hub device-identity delete \
        --hub-name "$iot_hub_name" \
        --device-id "$agent_id" \
        --output none
    
    # Clean up connection string file
    rm -f "agent-${agent_id}-connection.txt"
    
    print_success "Agent $agent_id removed"
}

# Show help
show_help() {
    echo "IoT Sound Analytics Swarm Manager"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  deploy-infrastructure    Deploy swarm infrastructure"
    echo "  register-agent <id> <location>  Register a new swarm agent"
    echo "  deploy-agent <id> <ip> <user>   Deploy agent to device"
    echo "  list-agents             List all swarm agents"
    echo "  monitor-swarm           Monitor swarm telemetry"
    echo "  update-config           Update swarm configuration"
    echo "  remove-agent <id>       Remove swarm agent"
    echo "  help                    Show this help message"
    echo
    echo "Examples:"
    echo "  $0 deploy-infrastructure"
    echo "  $0 register-agent agent-001 \"Moscow, Russia\""
    echo "  $0 deploy-agent agent-001 192.168.1.100 pi"
    echo "  $0 list-agents"
    echo "  $0 monitor-swarm"
}

# Main script logic
main() {
    print_header
    
    case "${1:-help}" in
        "deploy-infrastructure")
            check_prerequisites
            deploy_swarm_infrastructure
            ;;
        "register-agent")
            check_prerequisites
            register_swarm_agent "$2" "$3"
            ;;
        "deploy-agent")
            check_prerequisites
            deploy_agent_to_device "$2" "$3" "$4"
            ;;
        "list-agents")
            check_prerequisites
            list_swarm_agents
            ;;
        "monitor-swarm")
            check_prerequisites
            monitor_swarm
            ;;
        "update-config")
            check_prerequisites
            update_swarm_config
            ;;
        "remove-agent")
            check_prerequisites
            remove_swarm_agent "$2"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"


