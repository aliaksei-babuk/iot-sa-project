"""API dependencies for dependency injection."""
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Generator

from app.services.database import db_service
from app.services.device_service import DeviceService
from app.services.telemetry_service import TelemetryService
from app.services.alert_service import AlertService
from app.services.ml_service import ml_service
from app.services.mqtt_service import mqtt_service


def get_db() -> Generator[Session, None, None]:
    """Get database session."""
    session = db_service.get_session()
    try:
        yield session
    finally:
        db_service.close_session(session)


def get_device_service(db: Session = Depends(get_db)) -> DeviceService:
    """Get device service."""
    return DeviceService(db)


def get_telemetry_service(db: Session = Depends(get_db)) -> TelemetryService:
    """Get telemetry service."""
    return TelemetryService(db)


def get_alert_service(db: Session = Depends(get_db)) -> AlertService:
    """Get alert service."""
    return AlertService(db)


def get_ml_service():
    """Get ML service."""
    return ml_service


def get_mqtt_service():
    """Get MQTT service."""
    return mqtt_service
