"""Alert-related Pydantic schemas."""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime
from enum import Enum


class AlertType(str, Enum):
    """Alert type enumeration."""
    DRONE_DETECTED = "drone_detected"
    ANOMALY = "anomaly"
    SYSTEM_ERROR = "system_error"
    DEVICE_OFFLINE = "device_offline"


class AlertSeverity(str, Enum):
    """Alert severity enumeration."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AlertStatus(str, Enum):
    """Alert status enumeration."""
    ACTIVE = "active"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"


class AlertCreate(BaseModel):
    """Schema for creating an alert."""
    device_id: str = Field(..., description="Device identifier")
    alert_type: AlertType = Field(..., description="Type of alert")
    severity: AlertSeverity = Field(..., description="Alert severity")
    message: str = Field(..., description="Alert message")
    confidence_score: Optional[float] = Field(None, description="Detection confidence")
    location: Optional[str] = Field(None, description="Alert location")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")


class AlertUpdate(BaseModel):
    """Schema for updating alert status."""
    status: AlertStatus = Field(..., description="New alert status")
    notes: Optional[str] = Field(None, description="Additional notes")


class AlertResponse(BaseModel):
    """Schema for alert response."""
    id: str
    device_id: str
    alert_type: AlertType
    severity: AlertSeverity
    message: str
    confidence_score: Optional[float]
    location: Optional[str]
    status: AlertStatus
    created_at: datetime
    acknowledged_at: Optional[datetime]
    resolved_at: Optional[datetime]
    metadata: Optional[Dict[str, Any]]

    class Config:
        from_attributes = True


class AlertListResponse(BaseModel):
    """Schema for alert list response."""
    alerts: list[AlertResponse]
    total: int
    page: int
    page_size: int
