"""MQTT communication API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Dict, Any, Optional
import logging

from app.services.mqtt_service import MQTTService
from app.api.dependencies import get_mqtt_service

router = APIRouter(prefix="/mqtt", tags=["mqtt"])

logger = logging.getLogger(__name__)


@router.get("/status")
async def get_mqtt_status(
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Get MQTT connection status."""
    try:
        return {
            "connected": mqtt_service.is_connected(),
            "broker": f"{mqtt_service.client._host}:{mqtt_service.client._port}" if mqtt_service.client else "Not configured",
            "subscriptions": list(mqtt_service.subscriptions.keys())
        }
    except Exception as e:
        logger.error(f"Failed to get MQTT status: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get MQTT status")


@router.post("/connect")
async def connect_mqtt(
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Connect to MQTT broker."""
    try:
        success = mqtt_service.connect()
        if success:
            return {"message": "Connected to MQTT broker", "connected": True}
        else:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to connect to MQTT broker")
    except Exception as e:
        logger.error(f"Failed to connect to MQTT: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to connect: {str(e)}")


@router.post("/disconnect")
async def disconnect_mqtt(
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Disconnect from MQTT broker."""
    try:
        mqtt_service.disconnect()
        return {"message": "Disconnected from MQTT broker", "connected": False}
    except Exception as e:
        logger.error(f"Failed to disconnect from MQTT: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to disconnect: {str(e)}")


@router.post("/publish")
async def publish_message(
    topic: str = Query(..., description="MQTT topic"),
    message: Dict[str, Any] = Query(..., description="Message payload"),
    qos: int = Query(0, ge=0, le=2, description="Quality of Service level"),
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Publish message to MQTT topic."""
    try:
        if not mqtt_service.is_connected():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="MQTT client not connected")
        
        success = mqtt_service.publish(topic, message, qos)
        if success:
            return {"message": f"Message published to {topic}", "success": True}
        else:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to publish message")
    except Exception as e:
        logger.error(f"Failed to publish message: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to publish: {str(e)}")


@router.post("/publish/device-command")
async def publish_device_command(
    device_id: str = Query(..., description="Device ID"),
    command: Dict[str, Any] = Query(..., description="Command payload"),
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Publish command to specific device."""
    try:
        if not mqtt_service.is_connected():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="MQTT client not connected")
        
        success = mqtt_service.publish_device_command(device_id, command)
        if success:
            return {"message": f"Command sent to device {device_id}", "success": True}
        else:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to send command")
    except Exception as e:
        logger.error(f"Failed to publish device command: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to send command: {str(e)}")


@router.post("/publish/device-status")
async def publish_device_status(
    device_id: str = Query(..., description="Device ID"),
    status: str = Query(..., description="Device status"),
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Publish device status update."""
    try:
        if not mqtt_service.is_connected():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="MQTT client not connected")
        
        success = mqtt_service.publish_device_status(device_id, status)
        if success:
            return {"message": f"Status update sent for device {device_id}", "success": True}
        else:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to send status update")
    except Exception as e:
        logger.error(f"Failed to publish device status: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to send status: {str(e)}")


@router.get("/subscriptions")
async def get_subscriptions(
    mqtt_service: MQTTService = Depends(get_mqtt_service)
):
    """Get current MQTT subscriptions."""
    try:
        return {
            "subscriptions": list(mqtt_service.subscriptions.keys()),
            "handlers": list(mqtt_service.message_handlers.keys())
        }
    except Exception as e:
        logger.error(f"Failed to get subscriptions: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get subscriptions")
