"""Device management service."""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional, Tuple
from datetime import datetime
import logging

from app.models.database import Device
from app.schemas.device import DeviceCreate, DeviceUpdate, DeviceResponse, DeviceListResponse
from app.schemas.device import DeviceType, DeviceStatus

logger = logging.getLogger(__name__)


class DeviceService:
    """Service for managing IoT devices."""
    
    def __init__(self, db_session: Session):
        self.db = db_session
    
    def create_device(self, device_data: DeviceCreate) -> DeviceResponse:
        """Create a new device."""
        try:
            # Check if device already exists
            existing_device = self.db.query(Device).filter(
                Device.device_id == device_data.device_id
            ).first()
            
            if existing_device:
                raise ValueError(f"Device with ID {device_data.device_id} already exists")
            
            # Create new device
            device = Device(
                device_id=device_data.device_id,
                device_type=device_data.device_type.value,
                name=device_data.name,
                location=device_data.location,
                metadata=device_data.metadata
            )
            
            self.db.add(device)
            self.db.commit()
            self.db.refresh(device)
            
            logger.info(f"Device {device_data.device_id} created successfully")
            return DeviceResponse.from_orm(device)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to create device: {e}")
            raise
    
    def get_device(self, device_id: str) -> Optional[DeviceResponse]:
        """Get device by ID."""
        try:
            device = self.db.query(Device).filter(Device.device_id == device_id).first()
            if device:
                return DeviceResponse.from_orm(device)
            return None
        except Exception as e:
            logger.error(f"Failed to get device {device_id}: {e}")
            raise
    
    def get_device_by_db_id(self, db_id: str) -> Optional[DeviceResponse]:
        """Get device by database ID."""
        try:
            device = self.db.query(Device).filter(Device.id == db_id).first()
            if device:
                return DeviceResponse.from_orm(device)
            return None
        except Exception as e:
            logger.error(f"Failed to get device by DB ID {db_id}: {e}")
            raise
    
    def update_device(self, device_id: str, device_data: DeviceUpdate) -> Optional[DeviceResponse]:
        """Update device information."""
        try:
            device = self.db.query(Device).filter(Device.device_id == device_id).first()
            if not device:
                return None
            
            # Update fields
            if device_data.name is not None:
                device.name = device_data.name
            if device_data.location is not None:
                device.location = device_data.location
            if device_data.status is not None:
                device.status = device_data.status.value
            if device_data.metadata is not None:
                device.metadata = device_data.metadata
            
            device.updated_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(device)
            
            logger.info(f"Device {device_id} updated successfully")
            return DeviceResponse.from_orm(device)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to update device {device_id}: {e}")
            raise
    
    def delete_device(self, device_id: str) -> bool:
        """Delete device."""
        try:
            device = self.db.query(Device).filter(Device.device_id == device_id).first()
            if not device:
                return False
            
            self.db.delete(device)
            self.db.commit()
            
            logger.info(f"Device {device_id} deleted successfully")
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to delete device {device_id}: {e}")
            raise
    
    def list_devices(
        self, 
        page: int = 1, 
        page_size: int = 10,
        device_type: Optional[DeviceType] = None,
        status: Optional[DeviceStatus] = None,
        search: Optional[str] = None
    ) -> DeviceListResponse:
        """List devices with pagination and filtering."""
        try:
            query = self.db.query(Device)
            
            # Apply filters
            if device_type:
                query = query.filter(Device.device_type == device_type.value)
            if status:
                query = query.filter(Device.status == status.value)
            if search:
                query = query.filter(
                    or_(
                        Device.name.ilike(f"%{search}%"),
                        Device.device_id.ilike(f"%{search}%"),
                        Device.location.ilike(f"%{search}%")
                    )
                )
            
            # Get total count
            total = query.count()
            
            # Apply pagination
            offset = (page - 1) * page_size
            devices = query.offset(offset).limit(page_size).all()
            
            # Convert to response format
            device_responses = [DeviceResponse.from_orm(device) for device in devices]
            
            return DeviceListResponse(
                devices=device_responses,
                total=total,
                page=page,
                page_size=page_size
            )
            
        except Exception as e:
            logger.error(f"Failed to list devices: {e}")
            raise
    
    def update_device_status(self, device_id: str, status: DeviceStatus) -> bool:
        """Update device status."""
        try:
            device = self.db.query(Device).filter(Device.device_id == device_id).first()
            if not device:
                return False
            
            device.status = status.value
            device.last_seen = datetime.utcnow()
            device.updated_at = datetime.utcnow()
            
            self.db.commit()
            
            logger.info(f"Device {device_id} status updated to {status.value}")
            return True
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to update device status: {e}")
            raise
    
    def get_offline_devices(self, hours: int = 24) -> List[DeviceResponse]:
        """Get devices that haven't been seen for specified hours."""
        try:
            from datetime import timedelta
            cutoff_time = datetime.utcnow() - timedelta(hours=hours)
            
            devices = self.db.query(Device).filter(
                and_(
                    Device.last_seen < cutoff_time,
                    Device.status != DeviceStatus.OFFLINE.value
                )
            ).all()
            
            return [DeviceResponse.from_orm(device) for device in devices]
            
        except Exception as e:
            logger.error(f"Failed to get offline devices: {e}")
            raise
