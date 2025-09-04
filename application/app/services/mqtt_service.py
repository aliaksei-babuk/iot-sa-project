"""MQTT service for IoT device communication."""
import paho.mqtt.client as mqtt
import json
import logging
import threading
from typing import Callable, Optional, Dict, Any
from datetime import datetime

from app.config import settings

logger = logging.getLogger(__name__)


class MQTTService:
    """MQTT service for device communication."""
    
    def __init__(self):
        self.client = None
        self.connected = False
        self.subscriptions = {}
        self.message_handlers = {}
        self._setup_client()
    
    def _setup_client(self):
        """Setup MQTT client."""
        try:
            self.client = mqtt.Client()
            
            # Set callbacks
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            self.client.on_message = self._on_message
            self.client.on_log = self._on_log
            
            # Set credentials if provided
            if settings.mqtt_username and settings.mqtt_password:
                self.client.username_pw_set(settings.mqtt_username, settings.mqtt_password)
            
            logger.info("MQTT client setup completed")
            
        except Exception as e:
            logger.error(f"Failed to setup MQTT client: {e}")
            raise
    
    def connect(self) -> bool:
        """Connect to MQTT broker."""
        try:
            if not self.connected:
                self.client.connect(settings.mqtt_broker, settings.mqtt_port, 60)
                self.client.loop_start()
                
                # Wait for connection
                timeout = 10
                start_time = datetime.now()
                while not self.connected and (datetime.now() - start_time).seconds < timeout:
                    threading.Event().wait(0.1)
                
                if self.connected:
                    logger.info(f"Connected to MQTT broker at {settings.mqtt_broker}:{settings.mqtt_port}")
                    return True
                else:
                    logger.error("Failed to connect to MQTT broker within timeout")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to MQTT broker: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from MQTT broker."""
        try:
            if self.connected:
                self.client.loop_stop()
                self.client.disconnect()
                self.connected = False
                logger.info("Disconnected from MQTT broker")
        except Exception as e:
            logger.error(f"Failed to disconnect from MQTT broker: {e}")
    
    def _on_connect(self, client, userdata, flags, rc):
        """MQTT connection callback."""
        if rc == 0:
            self.connected = True
            logger.info("MQTT connection established")
            
            # Re-subscribe to existing topics
            for topic in self.subscriptions:
                self.client.subscribe(topic)
        else:
            self.connected = False
            logger.error(f"MQTT connection failed with code {rc}")
    
    def _on_disconnect(self, client, userdata, rc):
        """MQTT disconnection callback."""
        self.connected = False
        if rc != 0:
            logger.warning(f"MQTT unexpected disconnection (code {rc})")
        else:
            logger.info("MQTT disconnected")
    
    def _on_message(self, client, userdata, msg):
        """MQTT message callback."""
        try:
            topic = msg.topic
            payload = msg.payload.decode('utf-8')
            
            logger.debug(f"Received MQTT message on topic {topic}: {payload}")
            
            # Call registered handler for this topic
            if topic in self.message_handlers:
                try:
                    data = json.loads(payload)
                    self.message_handlers[topic](topic, data)
                except json.JSONDecodeError:
                    logger.error(f"Failed to parse JSON payload from topic {topic}")
                except Exception as e:
                    logger.error(f"Error in message handler for topic {topic}: {e}")
            
        except Exception as e:
            logger.error(f"Error processing MQTT message: {e}")
    
    def _on_log(self, client, userdata, level, buf):
        """MQTT log callback."""
        if settings.debug:
            logger.debug(f"MQTT: {buf}")
    
    def subscribe(self, topic: str, handler: Callable[[str, Dict[str, Any]], None]):
        """Subscribe to MQTT topic with message handler."""
        try:
            if not self.connected:
                logger.error("Cannot subscribe: MQTT client not connected")
                return False
            
            # Subscribe to topic
            result = self.client.subscribe(topic)
            if result[0] == mqtt.MQTT_ERR_SUCCESS:
                self.subscriptions[topic] = True
                self.message_handlers[topic] = handler
                logger.info(f"Subscribed to MQTT topic: {topic}")
                return True
            else:
                logger.error(f"Failed to subscribe to topic {topic}: {result}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to subscribe to topic {topic}: {e}")
            return False
    
    def unsubscribe(self, topic: str):
        """Unsubscribe from MQTT topic."""
        try:
            if topic in self.subscriptions:
                self.client.unsubscribe(topic)
                del self.subscriptions[topic]
                if topic in self.message_handlers:
                    del self.message_handlers[topic]
                logger.info(f"Unsubscribed from MQTT topic: {topic}")
                return True
            return False
            
        except Exception as e:
            logger.error(f"Failed to unsubscribe from topic {topic}: {e}")
            return False
    
    def publish(self, topic: str, payload: Dict[str, Any], qos: int = 0) -> bool:
        """Publish message to MQTT topic."""
        try:
            if not self.connected:
                logger.error("Cannot publish: MQTT client not connected")
                return False
            
            message = json.dumps(payload)
            result = self.client.publish(topic, message, qos)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                logger.debug(f"Published to MQTT topic {topic}: {message}")
                return True
            else:
                logger.error(f"Failed to publish to topic {topic}: {result.rc}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to publish to topic {topic}: {e}")
            return False
    
    def publish_device_command(self, device_id: str, command: Dict[str, Any]) -> bool:
        """Publish command to specific device."""
        topic = f"devices/{device_id}/commands"
        return self.publish(topic, command)
    
    def publish_device_status(self, device_id: str, status: str) -> bool:
        """Publish device status update."""
        topic = f"devices/{device_id}/status"
        payload = {
            "device_id": device_id,
            "status": status,
            "timestamp": datetime.utcnow().isoformat()
        }
        return self.publish(topic, payload)
    
    def is_connected(self) -> bool:
        """Check if MQTT client is connected."""
        return self.connected


# Global MQTT service instance
mqtt_service = MQTTService()
