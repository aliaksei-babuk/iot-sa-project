# IoT Swarm Configuration - Управление роем агентов

# IoT Device Group for Swarm Management
resource "azurerm_iothub_device_group" "swarm_agents" {
  name        = "swarm-agents"
  iothub_id   = azurerm_iothub.main.id
  condition   = "tags.swarmType = 'sound-agent'"
  priority    = 1
}

# Swarm Agent Device Template
resource "azurerm_iothub_device" "swarm_template" {
  count       = 0  # Template only - actual devices created via API
  name        = "swarm-agent-template"
  iothub_name = azurerm_iothub.main.name
  resource_group_name = var.resource_group_name

  authentication {
    type = "sas"
  }

  tags = {
    swarmType     = "sound-agent"
    agentVersion  = "2.0.0"
    location      = "unknown"
    status        = "inactive"
  }
}

# Swarm Management Configuration
resource "azurerm_iothub_shared_access_policy" "swarm_management" {
  name                = "swarm-management"
  resource_group_name = var.resource_group_name
  iothub_name         = azurerm_iothub.main.name

  registry_read  = true
  registry_write = true
  service_connect = true
  device_connect  = true
}

# Swarm Agent Deployment Configuration
resource "azurerm_iothub_configuration" "swarm_agents" {
  name                = "swarm-agents-config"
  resource_group_name = var.resource_group_name
  iothub_name         = azurerm_iothub.main.name

  content {
    device_content = jsonencode({
      properties = {
        desired = {
          swarmConfig = {
            enabled = true
            agentId = "{{deviceId}}"
            swarmId = "sound-analytics-swarm"
            heartbeatInterval = 30
            dataCollectionInterval = 5
            audioSettings = {
              sampleRate = 22050
              duration = 2.0
              channels = 1
              format = "wav"
            }
            mlSettings = {
              modelVersion = "2.0.0"
              confidenceThreshold = 0.7
              enableRealTimeProcessing = true
            }
            networkSettings = {
              retryAttempts = 3
              timeoutSeconds = 30
              enableCompression = true
            }
          }
        }
      }
    })
  }

  target_condition = "tags.swarmType = 'sound-agent'"
  priority = 1
}

# Swarm Health Monitoring
resource "azurerm_iothub_configuration" "swarm_health" {
  name                = "swarm-health-monitoring"
  resource_group_name = var.resource_group_name
  iothub_name         = azurerm_iothub.main.name

  content {
    device_content = jsonencode({
      properties = {
        desired = {
          healthMonitoring = {
            enabled = true
            reportInterval = 60
            metrics = [
              "cpu_usage",
              "memory_usage", 
              "disk_usage",
              "network_latency",
              "audio_quality",
              "ml_processing_time"
            ]
            alerts = {
              cpuThreshold = 80
              memoryThreshold = 85
              diskThreshold = 90
              latencyThreshold = 1000
            }
          }
        }
      }
    })
  }

  target_condition = "tags.swarmType = 'sound-agent'"
  priority = 2
}

# Swarm Agent Deployment Scripts
resource "azurerm_storage_blob" "swarm_deployment_script" {
  name                   = "swarm-agent-deploy.sh"
  storage_account_name   = azurerm_storage_account.iot_hub.name
  storage_container_name = azurerm_storage_container.iot_hub.name
  type                   = "Block"
  content_type           = "text/x-shellscript"

  content = <<-EOF
#!/bin/bash
# IoT Sound Analytics Swarm Agent Deployment Script

set -e

# Configuration
SWARM_ID="sound-analytics-swarm"
AGENT_VERSION="2.0.0"
IOT_HUB_CONNECTION_STRING="${azurerm_iothub_shared_access_policy.swarm_management.primary_connection_string}"

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip alsa-utils sox

# Install Python packages
pip3 install azure-iot-device azure-iot-hub-client librosa scikit-learn numpy soundfile

# Create agent directory
sudo mkdir -p /opt/iot-sound-agent
cd /opt/iot-sound-agent

# Download agent code
echo "Downloading agent code..."
# This would typically download from a repository or storage account
# For now, we'll create a basic structure

# Create agent configuration
cat > agent_config.json << 'EOL'
{
  "swarmId": "$SWARM_ID",
  "agentId": "$(hostname)",
  "version": "$AGENT_VERSION",
  "iotHubConnectionString": "$IOT_HUB_CONNECTION_STRING",
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
echo "Agent ID: $(hostname)"
echo "Swarm ID: $SWARM_ID"
echo "Status: $(sudo systemctl is-active iot-sound-agent)"
EOF
}

# Swarm Agent Python Code
resource "azurerm_storage_blob" "swarm_agent_code" {
  name                   = "agent.py"
  storage_account_name   = azurerm_storage_account.iot_hub.name
  storage_container_name = azurerm_storage_container.iot_hub.name
  type                   = "Block"
  content_type           = "text/x-python"

  content = <<-EOF
#!/usr/bin/env python3
"""
IoT Sound Analytics Swarm Agent
Manages audio collection, ML processing, and data transmission
"""

import json
import time
import logging
import asyncio
import soundfile as sf
import librosa
import numpy as np
from datetime import datetime
from azure.iot.device import IoTHubDeviceClient, Message
from azure.iot.device.exceptions import IoTHubError

# Configure logging
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
        self.version = self.config['version']
        
        logger.info(f"Swarm Agent {self.agent_id} initialized for swarm {self.swarm_id}")
    
    async def collect_audio(self):
        """Collect audio data from microphone"""
        try:
            # This is a simplified version - in production, you'd use proper audio capture
            duration = self.config['audioSettings']['duration']
            sample_rate = self.config['audioSettings']['sampleRate']
            
            # Generate synthetic audio for demo (replace with actual microphone capture)
            audio_data = np.random.randn(int(sample_rate * duration))
            
            return audio_data, sample_rate
        except Exception as e:
            logger.error(f"Audio collection failed: {e}")
            return None, None
    
    def process_audio(self, audio_data, sample_rate):
        """Process audio with ML models"""
        try:
            # Extract audio features
            mfccs = librosa.feature.mfcc(y=audio_data, sr=sample_rate, n_mfcc=13)
            spectral_centroids = librosa.feature.spectral_centroid(y=audio_data, sr=sample_rate)
            zero_crossing_rate = librosa.feature.zero_crossing_rate(audio_data)
            
            # Mock ML inference (replace with actual model)
            features = {
                'mfccs': mfccs.tolist(),
                'spectral_centroids': spectral_centroids.tolist(),
                'zero_crossing_rate': zero_crossing_rate.tolist()
            }
            
            # Mock classification results
            classification = {
                'drone_detected': np.random.random() > 0.7,
                'confidence': np.random.random(),
                'sound_type': np.random.choice(['traffic', 'siren', 'industrial', 'wildlife']),
                'timestamp': datetime.utcnow().isoformat()
            }
            
            return features, classification
        except Exception as e:
            logger.error(f"Audio processing failed: {e}")
            return None, None
    
    async def send_telemetry(self, features, classification):
        """Send telemetry data to IoT Hub"""
        try:
            message_data = {
                'agentId': self.agent_id,
                'swarmId': self.swarm_id,
                'timestamp': datetime.utcnow().isoformat(),
                'features': features,
                'classification': classification,
                'agentVersion': self.version
            }
            
            message = Message(json.dumps(message_data))
            message.content_type = "application/json"
            message.content_encoding = "utf-8"
            
            await self.client.send_message(message)
            logger.info(f"Telemetry sent: {classification['sound_type']}")
            
        except IoTHubError as e:
            logger.error(f"Failed to send telemetry: {e}")
    
    async def send_health_status(self):
        """Send health status to IoT Hub"""
        try:
            import psutil
            
            health_data = {
                'agentId': self.agent_id,
                'swarmId': self.swarm_id,
                'timestamp': datetime.utcnow().isoformat(),
                'health': {
                    'cpu_usage': psutil.cpu_percent(),
                    'memory_usage': psutil.virtual_memory().percent,
                    'disk_usage': psutil.disk_usage('/').percent,
                    'status': 'healthy'
                }
            }
            
            message = Message(json.dumps(health_data))
            message.content_type = "application/json"
            message.content_encoding = "utf-8"
            
            await self.client.send_message(message)
            logger.info("Health status sent")
            
        except Exception as e:
            logger.error(f"Failed to send health status: {e}")
    
    async def run(self):
        """Main agent loop"""
        logger.info("Starting swarm agent...")
        
        data_interval = self.config['audioSettings'].get('dataCollectionInterval', 5)
        health_interval = self.config.get('healthMonitoring', {}).get('reportInterval', 60)
        
        last_health_report = time.time()
        
        while True:
            try:
                # Collect and process audio
                audio_data, sample_rate = await self.collect_audio()
                if audio_data is not None:
                    features, classification = self.process_audio(audio_data, sample_rate)
                    if features is not None:
                        await self.send_telemetry(features, classification)
                
                # Send health status periodically
                current_time = time.time()
                if current_time - last_health_report >= health_interval:
                    await self.send_health_status()
                    last_health_report = current_time
                
                await asyncio.sleep(data_interval)
                
            except KeyboardInterrupt:
                logger.info("Agent stopped by user")
                break
            except Exception as e:
                logger.error(f"Agent error: {e}")
                await asyncio.sleep(5)  # Wait before retrying
        
        self.client.disconnect()

if __name__ == "__main__":
    agent = SwarmAgent()
    asyncio.run(agent.run())
EOF
}

# Swarm Management API Endpoints
resource "azurerm_function_app" "swarm_management" {
  name                = "${var.project_name}-${var.environment}-swarm-mgmt-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  app_service_plan_id = var.function_app_plan_id
  storage_account_name = azurerm_storage_account.iot_hub.name
  storage_account_access_key = azurerm_storage_account.iot_hub.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "IOT_HUB_CONNECTION_STRING" = azurerm_iothub_shared_access_policy.swarm_management.primary_connection_string
    "SWARM_ID" = "sound-analytics-swarm"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}


