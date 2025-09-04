"""Telemetry data API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
from typing import Optional, List
from datetime import datetime, timedelta

from app.services.telemetry_service import TelemetryService
from app.schemas.telemetry import (
    TelemetryDataCreate, TelemetryDataResponse, AudioDataCreate, ProcessingResult,
    DataType
)
from app.api.dependencies import get_telemetry_service

router = APIRouter(prefix="/telemetry", tags=["telemetry"])


@router.post("/", response_model=TelemetryDataResponse, status_code=status.HTTP_201_CREATED)
async def create_telemetry_data(
    data: TelemetryDataCreate,
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Create new telemetry data."""
    try:
        telemetry = telemetry_service.create_telemetry_data(data)
        return telemetry
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create telemetry data")


@router.post("/audio", response_model=TelemetryDataResponse, status_code=status.HTTP_201_CREATED)
async def upload_audio_data(
    device_id: str = Form(..., description="Device ID"),
    audio_file: UploadFile = File(..., description="Audio file"),
    sample_rate: int = Form(22050, description="Audio sample rate"),
    duration: float = Form(..., description="Audio duration in seconds"),
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Upload audio data for processing."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Create audio data
        audio_data_create = AudioDataCreate(
            device_id=device_id,
            audio_data=audio_data,
            sample_rate=sample_rate,
            duration=duration,
            metadata={
                "filename": audio_file.filename,
                "content_type": audio_file.content_type,
                "file_size": len(audio_data)
            }
        )
        
        telemetry = telemetry_service.create_audio_data(audio_data_create)
        return telemetry
        
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to upload audio: {str(e)}")


@router.get("/{device_id}", response_model=List[TelemetryDataResponse])
async def get_telemetry_data(
    device_id: str,
    start_time: Optional[datetime] = Query(None, description="Start time filter"),
    end_time: Optional[datetime] = Query(None, description="End time filter"),
    data_type: Optional[DataType] = Query(None, description="Filter by data type"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(100, ge=1, le=1000, description="Page size"),
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Get telemetry data for a device."""
    try:
        data, total = telemetry_service.get_telemetry_data(
            device_id=device_id,
            start_time=start_time,
            end_time=end_time,
            data_type=data_type,
            page=page,
            page_size=page_size
        )
        
        return {
            "data": data,
            "total": total,
            "page": page,
            "page_size": page_size
        }
        
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get telemetry data")


@router.get("/{device_id}/latest", response_model=List[TelemetryDataResponse])
async def get_latest_telemetry_data(
    device_id: str,
    limit: int = Query(10, ge=1, le=100, description="Number of latest records"),
    data_type: Optional[DataType] = Query(None, description="Filter by data type"),
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Get latest telemetry data for a device."""
    try:
        # Get data from last hour
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=1)
        
        data, total = telemetry_service.get_telemetry_data(
            device_id=device_id,
            start_time=start_time,
            end_time=end_time,
            data_type=data_type,
            page=1,
            page_size=limit
        )
        
        return data
        
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get latest telemetry data")


@router.get("/{device_id}/audio/{telemetry_id}/file")
async def get_audio_file(
    device_id: str,
    telemetry_id: str,
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Get audio file for telemetry data."""
    try:
        file_path = telemetry_service.get_audio_file_path(telemetry_id)
        if not file_path:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Audio file not found")
        
        # In a real implementation, you would return the file
        # For now, return the file path
        return {"file_path": file_path, "message": "Audio file found"}
        
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get audio file")


@router.get("/{device_id}/stats")
async def get_telemetry_stats(
    device_id: str,
    hours: int = Query(24, ge=1, le=168, description="Time range in hours"),
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Get telemetry statistics for a device."""
    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=hours)
        
        # Get all data in time range
        data, total = telemetry_service.get_telemetry_data(
            device_id=device_id,
            start_time=start_time,
            end_time=end_time,
            page=1,
            page_size=1000  # Large page size to get all data
        )
        
        # Calculate statistics
        audio_count = sum(1 for d in data if d.data_type == DataType.AUDIO)
        sensor_count = sum(1 for d in data if d.data_type == DataType.SENSOR)
        status_count = sum(1 for d in data if d.data_type == DataType.STATUS)
        
        processed_count = sum(1 for d in data if d.processed)
        
        return {
            "device_id": device_id,
            "time_range_hours": hours,
            "total_records": total,
            "audio_records": audio_count,
            "sensor_records": sensor_count,
            "status_records": status_count,
            "processed_records": processed_count,
            "processing_rate": processed_count / total if total > 0 else 0
        }
        
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get telemetry stats")
