"""Application configuration settings for Cloud-Native Serverless Sound Analytics."""
from pydantic_settings import BaseSettings
from typing import Optional, List, Dict, Any
import os
from enum import Enum


class UseCaseType(str, Enum):
    """Supported use case types."""
    TRAFFIC_MONITORING = "traffic_monitoring"
    SIREN_DETECTION = "siren_detection"
    NOISE_MAPPING = "noise_mapping"
    INDUSTRIAL_MONITORING = "industrial_monitoring"
    WILDLIFE_MONITORING = "wildlife_monitoring"


class CloudProvider(str, Enum):
    """Supported cloud providers."""
    AWS = "aws"
    AZURE = "azure"
    GCP = "gcp"


class Settings(BaseSettings):
    """Application settings for serverless sound analytics."""
    
    # Application
    app_name: str = "Cloud-Native Serverless Sound Analytics"
    app_version: str = "2.0.0"
    debug: bool = False
    environment: str = "development"
    
    # API Configuration
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_prefix: str = "/api/v1"
    
    # Performance Requirements (NFR-01)
    max_latency_ms: int = 100  # p95 end-to-end latency
    max_throughput_rps: int = 100  # events per second
    cold_start_timeout_ms: int = 200
    
    # Scalability Requirements (NFR-02)
    max_concurrent_devices: int = 10000
    auto_scaling_enabled: bool = True
    scaling_response_time_s: int = 30
    
    # Availability Requirements (NFR-03)
    target_uptime_percent: float = 99.9
    failover_time_s: int = 60
    health_check_timeout_s: int = 5
    
    # Database Configuration
    database_url: str = "postgresql://iot_user:iot_password@localhost:5432/iot_sound_db"
    database_pool_size: int = 20
    database_max_overflow: int = 30
    
    # Redis Configuration
    redis_url: str = "redis://localhost:6379/0"
    redis_max_connections: int = 100
    
    # MQTT Configuration
    mqtt_broker: str = "localhost"
    mqtt_port: int = 1883
    mqtt_username: Optional[str] = None
    mqtt_password: Optional[str] = None
    mqtt_qos_level: int = 1
    mqtt_keepalive: int = 60
    
    # Security Configuration (NFR-05)
    secret_key: str = "your-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    password_min_length: int = 8
    max_login_attempts: int = 5
    account_lockout_duration_minutes: int = 15
    
    # Encryption Settings
    encryption_key: str = "your-encryption-key-32-chars-long"
    enable_encryption_at_rest: bool = True
    enable_encryption_in_transit: bool = True
    
    # ML Model Configuration
    model_path: str = "models"
    audio_sample_rate: int = 22050
    audio_duration: float = 2.0
    max_audio_file_size_mb: int = 50
    
    # Use Case Specific Models
    traffic_model_path: str = "models/traffic_classification.pkl"
    siren_model_path: str = "models/siren_detection.pkl"
    noise_model_path: str = "models/noise_classification.pkl"
    industrial_model_path: str = "models/industrial_anomaly.pkl"
    wildlife_model_path: str = "models/wildlife_classification.pkl"
    
    # Audio Processing
    noise_reduction_enabled: bool = True
    spectral_features_enabled: bool = True
    mfcc_features_count: int = 13
    mel_spectrogram_bins: int = 128
    
    # Storage Configuration
    audio_storage_path: str = "storage/audio"
    model_storage_path: str = "storage/models"
    temp_storage_path: str = "storage/temp"
    
    # Data Lifecycle Management (NFR-08)
    hot_storage_retention_days: int = 7
    warm_storage_retention_days: int = 30
    cold_storage_retention_days: int = 365
    data_archival_enabled: bool = True
    
    # Monitoring and Observability (NFR-08)
    enable_metrics: bool = True
    metrics_port: int = 9090
    enable_tracing: bool = True
    enable_profiling: bool = False
    log_level: str = "INFO"
    
    # Prometheus Configuration
    prometheus_enabled: bool = True
    prometheus_port: int = 9090
    prometheus_path: str = "/metrics"
    
    # Grafana Configuration
    grafana_enabled: bool = True
    grafana_port: int = 3000
    grafana_admin_password: str = "admin"
    
    # Alerting Configuration
    alerting_enabled: bool = True
    alert_webhook_url: Optional[str] = None
    alert_email_enabled: bool = False
    alert_sms_enabled: bool = False
    
    # Cost Optimization (NFR-09)
    cost_per_event_limit: float = 0.01  # $0.01 per event
    resource_optimization_enabled: bool = True
    auto_scaling_cost_threshold: float = 0.8
    
    # Multi-Cloud Configuration (NFR-11, NFR-17)
    primary_cloud_provider: CloudProvider = CloudProvider.AWS
    multi_cloud_enabled: bool = True
    cloud_providers: List[CloudProvider] = [CloudProvider.AWS, CloudProvider.AZURE, CloudProvider.GCP]
    
    # AWS Configuration
    aws_region: str = "us-east-1"
    aws_access_key_id: Optional[str] = None
    aws_secret_access_key: Optional[str] = None
    
    # Azure Configuration
    azure_tenant_id: Optional[str] = None
    azure_client_id: Optional[str] = None
    azure_client_secret: Optional[str] = None
    azure_subscription_id: Optional[str] = None
    
    # GCP Configuration
    gcp_project_id: Optional[str] = None
    gcp_credentials_path: Optional[str] = None
    
    # Compliance and Privacy (NFR-06, NFR-18)
    gdpr_compliance_enabled: bool = True
    data_anonymization_enabled: bool = True
    audit_logging_enabled: bool = True
    data_retention_policy_days: int = 30
    
    # Testing Configuration (NFR-13)
    test_mode: bool = False
    test_data_path: str = "test_data"
    mock_ml_models: bool = True
    test_coverage_threshold: float = 90.0
    
    # Use Case Configuration
    enabled_use_cases: List[UseCaseType] = [
        UseCaseType.TRAFFIC_MONITORING,
        UseCaseType.SIREN_DETECTION,
        UseCaseType.NOISE_MAPPING,
        UseCaseType.INDUSTRIAL_MONITORING,
        UseCaseType.WILDLIFE_MONITORING
    ]
    
    # Traffic Monitoring Specific
    traffic_analysis_interval_s: int = 60
    congestion_threshold: float = 0.7
    honk_detection_enabled: bool = True
    
    # Siren Detection Specific
    siren_confidence_threshold: float = 0.8
    emergency_response_timeout_s: int = 30
    geolocation_enabled: bool = True
    
    # Noise Mapping Specific
    noise_measurement_interval_s: int = 300  # 5 minutes
    spl_calibration_enabled: bool = True
    leq_calculation_enabled: bool = True
    
    # Industrial Monitoring Specific
    anomaly_detection_threshold: float = 0.6
    predictive_maintenance_enabled: bool = True
    machinery_health_scoring: bool = True
    
    # Wildlife Monitoring Specific
    species_classification_enabled: bool = True
    biodiversity_tracking: bool = True
    migration_pattern_analysis: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        env_prefix = "SOUND_ANALYTICS_"


settings = Settings()
