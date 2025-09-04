"""Telemetry data management service."""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import List, Optional, Tuple
from datetime import datetime, timedelta
import logging
import os
import uuid
import json

from app.models.database import TelemetryData, Device
from app.schemas.telemetry import (
    TelemetryDataCreate, TelemetryDataResponse, AudioDataCreate, ProcessingResult
)
from app.schemas.telemetry import DataType

logger = logging.getLogger(__name__)


class TelemetryService:
    """Service for managing telemetry data."""
    
    def __init__(self, db_session: Session):
        self.db = db_session
    
    def create_telemetry_data(self, data: TelemetryDataCreate) -> TelemetryDataResponse:
        """Create new telemetry data entry."""
        try:
            # Verify device exists
            device = self.db.query(Device).filter(Device.device_id == data.device_id).first()
            if not device:
                raise ValueError(f"Device {data.device_id} not found")
            
            # Create telemetry data
            telemetry = TelemetryData(
                device_id=device.id,
                data_type=data.data_type.value,
                payload=data.payload,
                timestamp=data.timestamp or datetime.utcnow()
            )
            
            self.db.add(telemetry)
            self.db.commit()
            self.db.refresh(telemetry)
            
            logger.info(f"Telemetry data created for device {data.device_id}")
            return TelemetryDataResponse.from_orm(telemetry)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to create telemetry data: {e}")
            raise
    
    def create_audio_data(self, data: AudioDataCreate) -> TelemetryDataResponse:
        """Create audio telemetry data with file storage."""
        try:
            # Verify device exists
            device = self.db.query(Device).filter(Device.device_id == data.device_id).first()
            if not device:
                raise ValueError(f"Device {data.device_id} not found")
            
            # Generate unique filename
            file_id = str(uuid.uuid4())
            file_extension = "wav"  # Default to WAV format
            filename = f"{file_id}.{file_extension}"
            
            # Create storage directory if it doesn't exist
            from app.config import settings
            storage_dir = os.path.join(settings.audio_storage_path, data.device_id)
            os.makedirs(storage_dir, exist_ok=True)
            
            # Save audio file
            file_path = os.path.join(storage_dir, filename)
            with open(file_path, "wb") as f:
                f.write(data.audio_data)
            
            # Create payload with audio metadata
            payload = {
                "audio_file": filename,
                "sample_rate": data.sample_rate,
                "duration": data.duration,
                "file_size": len(data.audio_data),
                "metadata": data.metadata or {}
            }
            
            # Create telemetry data
            telemetry = TelemetryData(
                device_id=device.id,
                data_type=DataType.AUDIO.value,
                payload=payload,
                audio_file_path=file_path,
                timestamp=datetime.utcnow()
            )
            
            self.db.add(telemetry)
            self.db.commit()
            self.db.refresh(telemetry)
            
            logger.info(f"Audio data created for device {data.device_id}")
            return TelemetryDataResponse.from_orm(telemetry)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to create audio data: {e}")
            raise
    
    def get_telemetry_data(
        self, 
        device_id: str,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        data_type: Optional[DataType] = None,
        page: int = 1,
        page_size: int = 100
    ) -> Tuple[List[TelemetryDataResponse], int]:
        """Get telemetry data for a device with filtering."""
        try:
            # Get device
            device = self.db.query(Device).filter(Device.device_id == device_id).first()
            if not device:
                raise ValueError(f"Device {device_id} not found")
            
            # Build query
            query = self.db.query(TelemetryData).filter(TelemetryData.device_id == device.id)
            
            # Apply filters
            if start_time:
                query = query.filter(TelemetryData.timestamp >= start_time)
            if end_time:
                query = query.filter(TelemetryData.timestamp <= end_time)
            if data_type:
                query = query.filter(TelemetryData.data_type == data_type.value)
            
            # Get total count
            total = query.count()
            
            # Apply pagination and ordering
            offset = (page - 1) * page_size
            telemetry_data = query.order_by(desc(TelemetryData.timestamp)).offset(offset).limit(page_size).all()
            
            # Convert to response format
            responses = [TelemetryDataResponse.from_orm(data) for data in telemetry_data]
            
            return responses, total
            
        except Exception as e:
            logger.error(f"Failed to get telemetry data: {e}")
            raise
    
    def get_unprocessed_audio_data(self, limit: int = 10) -> List[TelemetryDataResponse]:
        """Get unprocessed audio data for ML processing."""
        try:
            query = self.db.query(TelemetryData).filter(
                and_(
                    TelemetryData.data_type == DataType.AUDIO.value,
                    TelemetryData.processed == False,
                    TelemetryData.audio_file_path.isnot(None)
                )
            ).limit(limit)
            
            data = query.all()
            return [TelemetryDataResponse.from_orm(d) for d in data]
            
        except Exception as e:
            logger.error(f"Failed to get unprocessed audio data: {e}")
            raise
    
    def update_processing_result(
        self, 
        telemetry_id: str, 
        result: ProcessingResult
    ) -> bool:
        """Update telemetry data with ML processing results."""
        try:
            telemetry = self.db.query(TelemetryData).filter(TelemetryData.id == telemetry_id).first()
            if not telemetry:
                return False
            
            telemetry.processed = True
            telemetry.processing_result = result.dict()
            
            self.db.commit()
            
            logger.info(f"Processing result updated for telemetry {telemetry_id}")
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to update processing result: {e}")
            raise
    
    def get_audio_file_path(self, telemetry_id: str) -> Optional[str]:
        """Get audio file path for telemetry data."""
        try:
            telemetry = self.db.query(TelemetryData).filter(TelemetryData.id == telemetry_id).first()
            if telemetry and telemetry.audio_file_path:
                return telemetry.audio_file_path
            return None
        except Exception as e:
            logger.error(f"Failed to get audio file path: {e}")
            raise
    
    def cleanup_old_data(self, days: int = 30) -> int:
        """Clean up old telemetry data."""
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # Count records to be deleted
            count = self.db.query(TelemetryData).filter(
                TelemetryData.created_at < cutoff_date
            ).count()
            
            # Delete old records
            self.db.query(TelemetryData).filter(
                TelemetryData.created_at < cutoff_date
            ).delete()
            
            self.db.commit()
            
            logger.info(f"Cleaned up {count} old telemetry records")
            return count
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to cleanup old data: {e}")
            raise
