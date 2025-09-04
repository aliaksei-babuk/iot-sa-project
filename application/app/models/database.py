"""Database models for IoT sound detection system."""
from sqlalchemy import Column, Integer, String, DateTime, Float, Boolean, Text, ForeignKey, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

Base = declarative_base()


class Device(Base):
    """IoT device model."""
    __tablename__ = "devices"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = Column(String, unique=True, nullable=False, index=True)
    device_type = Column(String, nullable=False)  # drone, sensor, gateway
    name = Column(String, nullable=False)
    location = Column(String, nullable=True)
    status = Column(String, default="offline")  # online, offline, error
    last_seen = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    metadata = Column(JSON, nullable=True)
    
    # Relationships
    telemetry_data = relationship("TelemetryData", back_populates="device")
    alerts = relationship("Alert", back_populates="device")


class TelemetryData(Base):
    """Telemetry data from IoT devices."""
    __tablename__ = "telemetry_data"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = Column(String, ForeignKey("devices.id"), nullable=False, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)
    data_type = Column(String, nullable=False)  # audio, sensor, status
    payload = Column(JSON, nullable=False)
    audio_file_path = Column(String, nullable=True)
    processed = Column(Boolean, default=False)
    processing_result = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    device = relationship("Device", back_populates="telemetry_data")


class Alert(Base):
    """Alert/notification model."""
    __tablename__ = "alerts"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = Column(String, ForeignKey("devices.id"), nullable=False, index=True)
    alert_type = Column(String, nullable=False)  # drone_detected, anomaly, system_error
    severity = Column(String, nullable=False)  # low, medium, high, critical
    message = Column(Text, nullable=False)
    confidence_score = Column(Float, nullable=True)
    location = Column(String, nullable=True)
    status = Column(String, default="active")  # active, acknowledged, resolved
    created_at = Column(DateTime, default=datetime.utcnow)
    acknowledged_at = Column(DateTime, nullable=True)
    resolved_at = Column(DateTime, nullable=True)
    metadata = Column(JSON, nullable=True)
    
    # Relationships
    device = relationship("Device", back_populates="alerts")


class User(Base):
    """User model for authentication and authorization."""
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String, unique=True, nullable=False, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="operator")  # admin, operator, researcher
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    api_keys = relationship("APIKey", back_populates="user")


class APIKey(Base):
    """API key model for device authentication."""
    __tablename__ = "api_keys"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    key_name = Column(String, nullable=False)
    key_hash = Column(String, nullable=False, unique=True, index=True)
    permissions = Column(JSON, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_used = Column(DateTime, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="api_keys")


class MLModel(Base):
    """ML model metadata."""
    __tablename__ = "ml_models"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    version = Column(String, nullable=False)
    model_type = Column(String, nullable=False)  # drone_detection, sound_classification
    file_path = Column(String, nullable=False)
    accuracy = Column(Float, nullable=True)
    is_active = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    metadata = Column(JSON, nullable=True)
