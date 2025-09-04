"""Device-related Pydantic schemas."""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum


class DeviceType(str, Enum):
    """Device type enumeration."""
    DRONE = "drone"
    SENSOR = "sensor"
    GATEWAY = "gateway"


class DeviceStatus(str, Enum):
    """Device status enumeration."""
    ONLINE = "online"
    OFFLINE = "offline"
    ERROR = "error"


class DeviceCreate(BaseModel):
    """Schema for creating a new device."""
    device_id: str = Field(..., description="Unique device identifier")
    device_type: DeviceType = Field(..., description="Type of device")
    name: str = Field(..., description="Human-readable device name")
    location: Optional[str] = Field(None, description="Device location")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional device metadata")


class DeviceUpdate(BaseModel):
    """Schema for updating device information."""
    name: Optional[str] = Field(None, description="Human-readable device name")
    location: Optional[str] = Field(None, description="Device location")
    status: Optional[DeviceStatus] = Field(None, description="Device status")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional device metadata")


class DeviceResponse(BaseModel):
    """Schema for device response."""
    id: str
    device_id: str
    device_type: DeviceType
    name: str
    location: Optional[str]
    status: DeviceStatus
    last_seen: datetime
    created_at: datetime
    updated_at: datetime
    metadata: Optional[Dict[str, Any]]

    class Config:
        from_attributes = True


class DeviceListResponse(BaseModel):
    """Schema for device list response."""
    devices: list[DeviceResponse]
    total: int
    page: int
    page_size: int
