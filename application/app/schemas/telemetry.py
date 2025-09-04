"""Telemetry data Pydantic schemas."""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, Union
from datetime import datetime
from enum import Enum


class DataType(str, Enum):
    """Telemetry data type enumeration."""
    AUDIO = "audio"
    SENSOR = "sensor"
    STATUS = "status"


class TelemetryDataCreate(BaseModel):
    """Schema for creating telemetry data."""
    device_id: str = Field(..., description="Device identifier")
    data_type: DataType = Field(..., description="Type of telemetry data")
    payload: Dict[str, Any] = Field(..., description="Telemetry payload")
    timestamp: Optional[datetime] = Field(None, description="Data timestamp")


class TelemetryDataResponse(BaseModel):
    """Schema for telemetry data response."""
    id: str
    device_id: str
    timestamp: datetime
    data_type: DataType
    payload: Dict[str, Any]
    audio_file_path: Optional[str]
    processed: bool
    processing_result: Optional[Dict[str, Any]]
    created_at: datetime

    class Config:
        from_attributes = True


class AudioDataCreate(BaseModel):
    """Schema for audio data upload."""
    device_id: str = Field(..., description="Device identifier")
    audio_data: bytes = Field(..., description="Audio data as bytes")
    sample_rate: int = Field(22050, description="Audio sample rate")
    duration: float = Field(..., description="Audio duration in seconds")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Audio metadata")


class ProcessingResult(BaseModel):
    """Schema for ML processing results."""
    is_drone_detected: bool = Field(..., description="Whether drone was detected")
    confidence_score: float = Field(..., description="Detection confidence score")
    classification: Optional[str] = Field(None, description="Sound classification")
    features: Optional[Dict[str, Any]] = Field(None, description="Extracted features")
    processing_time: float = Field(..., description="Processing time in seconds")
