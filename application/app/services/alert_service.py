"""Alert management service."""
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc
from typing import List, Optional
from datetime import datetime
import logging

from app.models.database import Alert, Device
from app.schemas.alert import (
    AlertCreate, AlertUpdate, AlertResponse, AlertListResponse
)
from app.schemas.alert import AlertType, AlertSeverity, AlertStatus

logger = logging.getLogger(__name__)


class AlertService:
    """Service for managing alerts and notifications."""
    
    def __init__(self, db_session: Session):
        self.db = db_session
    
    def create_alert(self, alert_data: AlertCreate) -> AlertResponse:
        """Create a new alert."""
        try:
            # Verify device exists
            device = self.db.query(Device).filter(Device.device_id == alert_data.device_id).first()
            if not device:
                raise ValueError(f"Device {alert_data.device_id} not found")
            
            # Create alert
            alert = Alert(
                device_id=device.id,
                alert_type=alert_data.alert_type.value,
                severity=alert_data.severity.value,
                message=alert_data.message,
                confidence_score=alert_data.confidence_score,
                location=alert_data.location,
                metadata=alert_data.metadata
            )
            
            self.db.add(alert)
            self.db.commit()
            self.db.refresh(alert)
            
            logger.info(f"Alert created for device {alert_data.device_id}: {alert_data.alert_type}")
            return AlertResponse.from_orm(alert)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to create alert: {e}")
            raise
    
    def get_alert(self, alert_id: str) -> Optional[AlertResponse]:
        """Get alert by ID."""
        try:
            alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
            if alert:
                return AlertResponse.from_orm(alert)
            return None
        except Exception as e:
            logger.error(f"Failed to get alert {alert_id}: {e}")
            raise
    
    def update_alert(self, alert_id: str, alert_data: AlertUpdate) -> Optional[AlertResponse]:
        """Update alert status."""
        try:
            alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
            if not alert:
                return None
            
            # Update status
            alert.status = alert_data.status.value
            
            # Update timestamps based on status
            if alert_data.status == AlertStatus.ACKNOWLEDGED and alert.status != AlertStatus.ACKNOWLEDGED.value:
                alert.acknowledged_at = datetime.utcnow()
            elif alert_data.status == AlertStatus.RESOLVED and alert.status != AlertStatus.RESOLVED.value:
                alert.resolved_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(alert)
            
            logger.info(f"Alert {alert_id} updated to {alert_data.status.value}")
            return AlertResponse.from_orm(alert)
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to update alert {alert_id}: {e}")
            raise
    
    def list_alerts(
        self,
        device_id: Optional[str] = None,
        alert_type: Optional[AlertType] = None,
        severity: Optional[AlertSeverity] = None,
        status: Optional[AlertStatus] = None,
        page: int = 1,
        page_size: int = 50
    ) -> AlertListResponse:
        """List alerts with filtering and pagination."""
        try:
            query = self.db.query(Alert)
            
            # Apply filters
            if device_id:
                device = self.db.query(Device).filter(Device.device_id == device_id).first()
                if device:
                    query = query.filter(Alert.device_id == device.id)
                else:
                    # Return empty result if device not found
                    return AlertListResponse(
                        alerts=[],
                        total=0,
                        page=page,
                        page_size=page_size
                    )
            
            if alert_type:
                query = query.filter(Alert.alert_type == alert_type.value)
            if severity:
                query = query.filter(Alert.severity == severity.value)
            if status:
                query = query.filter(Alert.status == status.value)
            
            # Get total count
            total = query.count()
            
            # Apply pagination and ordering
            offset = (page - 1) * page_size
            alerts = query.order_by(desc(Alert.created_at)).offset(offset).limit(page_size).all()
            
            # Convert to response format
            alert_responses = [AlertResponse.from_orm(alert) for alert in alerts]
            
            return AlertListResponse(
                alerts=alert_responses,
                total=total,
                page=page,
                page_size=page_size
            )
            
        except Exception as e:
            logger.error(f"Failed to list alerts: {e}")
            raise
    
    def get_active_alerts(self, device_id: Optional[str] = None) -> List[AlertResponse]:
        """Get active alerts."""
        try:
            query = self.db.query(Alert).filter(Alert.status == AlertStatus.ACTIVE.value)
            
            if device_id:
                device = self.db.query(Device).filter(Device.device_id == device_id).first()
                if device:
                    query = query.filter(Alert.device_id == device.id)
            
            alerts = query.order_by(desc(Alert.created_at)).all()
            return [AlertResponse.from_orm(alert) for alert in alerts]
            
        except Exception as e:
            logger.error(f"Failed to get active alerts: {e}")
            raise
    
    def get_critical_alerts(self) -> List[AlertResponse]:
        """Get critical alerts."""
        try:
            alerts = self.db.query(Alert).filter(
                and_(
                    Alert.severity == AlertSeverity.CRITICAL.value,
                    Alert.status == AlertStatus.ACTIVE.value
                )
            ).order_by(desc(Alert.created_at)).all()
            
            return [AlertResponse.from_orm(alert) for alert in alerts]
            
        except Exception as e:
            logger.error(f"Failed to get critical alerts: {e}")
            raise
    
    def acknowledge_alert(self, alert_id: str) -> bool:
        """Acknowledge an alert."""
        try:
            alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
            if not alert:
                return False
            
            if alert.status == AlertStatus.ACTIVE.value:
                alert.status = AlertStatus.ACKNOWLEDGED.value
                alert.acknowledged_at = datetime.utcnow()
                
                self.db.commit()
                
                logger.info(f"Alert {alert_id} acknowledged")
                return True
            
            return False
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to acknowledge alert {alert_id}: {e}")
            raise
    
    def resolve_alert(self, alert_id: str) -> bool:
        """Resolve an alert."""
        try:
            alert = self.db.query(Alert).filter(Alert.id == alert_id).first()
            if not alert:
                return False
            
            if alert.status in [AlertStatus.ACTIVE.value, AlertStatus.ACKNOWLEDGED.value]:
                alert.status = AlertStatus.RESOLVED.value
                alert.resolved_at = datetime.utcnow()
                
                self.db.commit()
                
                logger.info(f"Alert {alert_id} resolved")
                return True
            
            return False
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to resolve alert {alert_id}: {e}")
            raise
    
    def cleanup_resolved_alerts(self, days: int = 30) -> int:
        """Clean up old resolved alerts."""
        try:
            from datetime import timedelta
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # Count records to be deleted
            count = self.db.query(Alert).filter(
                and_(
                    Alert.status == AlertStatus.RESOLVED.value,
                    Alert.resolved_at < cutoff_date
                )
            ).count()
            
            # Delete old resolved alerts
            self.db.query(Alert).filter(
                and_(
                    Alert.status == AlertStatus.RESOLVED.value,
                    Alert.resolved_at < cutoff_date
                )
            ).delete()
            
            self.db.commit()
            
            logger.info(f"Cleaned up {count} old resolved alerts")
            return count
            
        except Exception as e:
            self.db.rollback()
            logger.error(f"Failed to cleanup resolved alerts: {e}")
            raise
