"""Device management API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional
from datetime import datetime

from app.services.device_service import DeviceService
from app.schemas.device import (
    DeviceCreate, DeviceUpdate, DeviceResponse, DeviceListResponse,
    DeviceType, DeviceStatus
)
from app.api.dependencies import get_device_service

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("/", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
async def create_device(
    device_data: DeviceCreate,
    device_service: DeviceService = Depends(get_device_service)
):
    """Create a new IoT device."""
    try:
        device = device_service.create_device(device_data)
        return device
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create device")


@router.get("/", response_model=DeviceListResponse)
async def list_devices(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(10, ge=1, le=100, description="Page size"),
    device_type: Optional[DeviceType] = Query(None, description="Filter by device type"),
    status: Optional[DeviceStatus] = Query(None, description="Filter by device status"),
    search: Optional[str] = Query(None, description="Search in device name, ID, or location"),
    device_service: DeviceService = Depends(get_device_service)
):
    """List devices with pagination and filtering."""
    try:
        result = device_service.list_devices(
            page=page,
            page_size=page_size,
            device_type=device_type,
            status=status,
            search=search
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to list devices")


@router.get("/{device_id}", response_model=DeviceResponse)
async def get_device(
    device_id: str,
    device_service: DeviceService = Depends(get_device_service)
):
    """Get device by ID."""
    device = device_service.get_device(device_id)
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")
    return device


@router.put("/{device_id}", response_model=DeviceResponse)
async def update_device(
    device_id: str,
    device_data: DeviceUpdate,
    device_service: DeviceService = Depends(get_device_service)
):
    """Update device information."""
    device = device_service.update_device(device_id, device_data)
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")
    return device


@router.delete("/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_device(
    device_id: str,
    device_service: DeviceService = Depends(get_device_service)
):
    """Delete device."""
    success = device_service.delete_device(device_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")


@router.patch("/{device_id}/status", response_model=DeviceResponse)
async def update_device_status(
    device_id: str,
    status: DeviceStatus,
    device_service: DeviceService = Depends(get_device_service)
):
    """Update device status."""
    success = device_service.update_device_status(device_id, status)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")
    
    # Return updated device
    device = device_service.get_device(device_id)
    return device


@router.get("/{device_id}/health")
async def get_device_health(
    device_id: str,
    device_service: DeviceService = Depends(get_device_service)
):
    """Get device health status."""
    device = device_service.get_device(device_id)
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")
    
    # Calculate health metrics
    now = datetime.utcnow()
    time_since_last_seen = (now - device.last_seen).total_seconds()
    
    health_status = "healthy"
    if device.status == DeviceStatus.OFFLINE:
        health_status = "offline"
    elif time_since_last_seen > 3600:  # 1 hour
        health_status = "warning"
    elif time_since_last_seen > 86400:  # 24 hours
        health_status = "critical"
    
    return {
        "device_id": device.device_id,
        "status": device.status,
        "health": health_status,
        "last_seen": device.last_seen,
        "time_since_last_seen_seconds": time_since_last_seen,
        "uptime_percentage": 95.0  # Mock uptime percentage
    }
