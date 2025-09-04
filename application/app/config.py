"""Application configuration settings."""
from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings."""
    
    # Application
    app_name: str = "IoT Sound Detection POC"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    
    # Database
    database_url: str = "postgresql://user:password@localhost:5432/iot_sound_db"
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # MQTT
    mqtt_broker: str = "localhost"
    mqtt_port: int = 1883
    mqtt_username: Optional[str] = None
    mqtt_password: Optional[str] = None
    
    # Security
    secret_key: str = "your-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # ML Model
    model_path: str = "models/drone_detection_model.pkl"
    audio_sample_rate: int = 22050
    audio_duration: float = 2.0
    
    # Storage
    audio_storage_path: str = "storage/audio"
    model_storage_path: str = "storage/models"
    
    # Monitoring
    enable_metrics: bool = True
    metrics_port: int = 9090
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
