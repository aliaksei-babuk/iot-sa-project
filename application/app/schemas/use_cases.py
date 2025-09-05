"""Use case specific Pydantic schemas."""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum
from app.config import UseCaseType


class TrafficEventType(str, Enum):
    """Traffic event types."""
    HONK = "honk"
    CONGESTION = "congestion"
    INCIDENT = "incident"
    NORMAL_FLOW = "normal_flow"
    EMERGENCY_VEHICLE = "emergency_vehicle"


class SirenType(str, Enum):
    """Siren types for emergency detection."""
    AMBULANCE = "ambulance"
    FIRE_TRUCK = "fire_truck"
    POLICE = "police"
    EMERGENCY = "emergency"
    CIVIL_DEFENSE = "civil_defense"


class NoiseLevel(str, Enum):
    """Noise level classifications."""
    QUIET = "quiet"  # < 40 dB
    MODERATE = "moderate"  # 40-60 dB
    LOUD = "loud"  # 60-80 dB
    VERY_LOUD = "very_loud"  # 80-100 dB
    EXTREME = "extreme"  # > 100 dB


class IndustrialAnomalyType(str, Enum):
    """Industrial anomaly types."""
    BEARING_FAILURE = "bearing_failure"
    BELT_MISALIGNMENT = "belt_misalignment"
    CAVITATION = "cavitation"
    IMPACT_DAMAGE = "impact_damage"
    LUBRICATION_ISSUE = "lubrication_issue"
    NORMAL_OPERATION = "normal_operation"


class WildlifeSpecies(str, Enum):
    """Wildlife species for classification."""
    BIRD = "bird"
    MAMMAL = "mammal"
    INSECT = "insect"
    AMPHIBIAN = "amphibian"
    REPTILE = "reptile"
    UNKNOWN = "unknown"


# Traffic Monitoring Schemas
class TrafficAnalysisRequest(BaseModel):
    """Request for traffic analysis."""
    device_id: str = Field(..., description="Device identifier")
    location: str = Field(..., description="Geographic location")
    audio_data: bytes = Field(..., description="Audio data for analysis")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")


class TrafficAnalysisResult(BaseModel):
    """Result of traffic analysis."""
    device_id: str
    location: str
    timestamp: datetime
    event_type: TrafficEventType
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    traffic_density: float = Field(..., ge=0.0, le=1.0)
    congestion_level: float = Field(..., ge=0.0, le=1.0)
    honk_count: int = Field(..., ge=0)
    vehicle_count_estimate: int = Field(..., ge=0)
    processing_time_ms: float
    features: Dict[str, Any]


# Siren Detection Schemas
class SirenDetectionRequest(BaseModel):
    """Request for siren detection."""
    device_id: str = Field(..., description="Device identifier")
    location: str = Field(..., description="Geographic location")
    audio_data: bytes = Field(..., description="Audio data for analysis")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    emergency_priority: bool = Field(False, description="High priority emergency")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")


class SirenDetectionResult(BaseModel):
    """Result of siren detection."""
    device_id: str
    location: str
    timestamp: datetime
    siren_detected: bool
    siren_type: Optional[SirenType] = None
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    direction_estimate: Optional[float] = Field(None, ge=0.0, le=360.0)
    distance_estimate: Optional[float] = Field(None, ge=0.0)
    emergency_level: int = Field(..., ge=1, le=5)
    processing_time_ms: float
    features: Dict[str, Any]


# Noise Mapping Schemas
class NoiseMappingRequest(BaseModel):
    """Request for noise mapping analysis."""
    device_id: str = Field(..., description="Device identifier")
    location: str = Field(..., description="Geographic location")
    audio_data: bytes = Field(..., description="Audio data for analysis")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    measurement_duration_s: int = Field(300, ge=60, le=3600)
    calibration_data: Optional[Dict[str, Any]] = Field(None)
    metadata: Optional[Dict[str, Any]] = Field(None)


class NoiseMappingResult(BaseModel):
    """Result of noise mapping analysis."""
    device_id: str
    location: str
    timestamp: datetime
    spl_db: float = Field(..., description="Sound Pressure Level in dB")
    leq_db: float = Field(..., description="Equivalent Continuous Sound Level")
    lmax_db: float = Field(..., description="Maximum sound level")
    lmin_db: float = Field(..., description="Minimum sound level")
    noise_level: NoiseLevel
    frequency_analysis: Dict[str, float]
    temporal_pattern: List[float]
    processing_time_ms: float
    features: Dict[str, Any]


# Industrial Monitoring Schemas
class IndustrialMonitoringRequest(BaseModel):
    """Request for industrial monitoring analysis."""
    device_id: str = Field(..., description="Device identifier")
    machinery_id: str = Field(..., description="Machinery identifier")
    location: str = Field(..., description="Geographic location")
    audio_data: bytes = Field(..., description="Audio data for analysis")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    machinery_type: str = Field(..., description="Type of machinery")
    operating_conditions: Optional[Dict[str, Any]] = Field(None)
    metadata: Optional[Dict[str, Any]] = Field(None)


class IndustrialMonitoringResult(BaseModel):
    """Result of industrial monitoring analysis."""
    device_id: str
    machinery_id: str
    location: str
    timestamp: datetime
    anomaly_detected: bool
    anomaly_type: Optional[IndustrialAnomalyType] = None
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    health_score: float = Field(..., ge=0.0, le=1.0)
    vibration_level: float = Field(..., ge=0.0, le=1.0)
    temperature_estimate: Optional[float] = Field(None)
    maintenance_recommendation: Optional[str] = None
    processing_time_ms: float
    features: Dict[str, Any]


# Wildlife Monitoring Schemas
class WildlifeMonitoringRequest(BaseModel):
    """Request for wildlife monitoring analysis."""
    device_id: str = Field(..., description="Device identifier")
    location: str = Field(..., description="Geographic location")
    audio_data: bytes = Field(..., description="Audio data for analysis")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    habitat_type: str = Field(..., description="Type of habitat")
    season: Optional[str] = Field(None, description="Season of the year")
    time_of_day: Optional[str] = Field(None, description="Time of day")
    metadata: Optional[Dict[str, Any]] = Field(None)


class WildlifeMonitoringResult(BaseModel):
    """Result of wildlife monitoring analysis."""
    device_id: str
    location: str
    timestamp: datetime
    species_detected: List[str]
    species_confidence: Dict[str, float]
    biodiversity_index: float = Field(..., ge=0.0, le=1.0)
    activity_level: float = Field(..., ge=0.0, le=1.0)
    migration_indicator: bool = False
    conservation_status: Optional[str] = None
    processing_time_ms: float
    features: Dict[str, Any]


# Unified Analysis Schemas
class UnifiedAnalysisRequest(BaseModel):
    """Unified request for sound analysis."""
    device_id: str = Field(..., description="Device identifier")
    location: str = Field(..., description="Geographic location")
    audio_data: bytes = Field(..., description="Audio data for analysis")
    use_cases: List[UseCaseType] = Field(..., description="Use cases to analyze")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    priority: int = Field(1, ge=1, le=5, description="Analysis priority")
    metadata: Optional[Dict[str, Any]] = Field(None)


class UnifiedAnalysisResult(BaseModel):
    """Unified result of sound analysis."""
    device_id: str
    location: str
    timestamp: datetime
    use_cases: List[UseCaseType]
    results: Dict[UseCaseType, Dict[str, Any]]
    overall_confidence: float = Field(..., ge=0.0, le=1.0)
    processing_time_ms: float
    alerts_generated: List[str]
    recommendations: List[str]


# Dashboard and Visualization Schemas
class DashboardMetrics(BaseModel):
    """Dashboard metrics for visualization."""
    timestamp: datetime
    device_count: int
    active_devices: int
    events_processed: int
    alerts_generated: int
    system_health: float = Field(..., ge=0.0, le=1.0)
    performance_metrics: Dict[str, float]
    cost_metrics: Dict[str, float]


class HeatmapData(BaseModel):
    """Heatmap data for spatial visualization."""
    location: str
    timestamp: datetime
    value: float
    category: str
    confidence: float = Field(..., ge=0.0, le=1.0)


class TimeSeriesData(BaseModel):
    """Time series data for temporal analysis."""
    timestamp: datetime
    value: float
    category: str
    device_id: str
    metadata: Optional[Dict[str, Any]] = None


# Alert and Notification Schemas
class AlertSeverity(str, Enum):
    """Alert severity levels."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"
    EMERGENCY = "emergency"


class AlertType(str, Enum):
    """Alert types."""
    TRAFFIC_CONGESTION = "traffic_congestion"
    EMERGENCY_SIREN = "emergency_siren"
    NOISE_VIOLATION = "noise_violation"
    MACHINERY_ANOMALY = "machinery_anomaly"
    WILDLIFE_ALERT = "wildlife_alert"
    SYSTEM_ERROR = "system_error"
    PERFORMANCE_DEGRADATION = "performance_degradation"


class AlertRequest(BaseModel):
    """Alert generation request."""
    alert_type: AlertType
    severity: AlertSeverity
    device_id: str
    location: str
    message: str
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    metadata: Optional[Dict[str, Any]] = None
    auto_resolve: bool = False
    escalation_timeout_minutes: int = 30


class AlertResponse(BaseModel):
    """Alert response."""
    alert_id: str
    alert_type: AlertType
    severity: AlertSeverity
    device_id: str
    location: str
    message: str
    confidence_score: float
    status: str
    created_at: datetime
    resolved_at: Optional[datetime] = None
    metadata: Optional[Dict[str, Any]] = None
