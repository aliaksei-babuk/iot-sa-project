"""Use case specific API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
from typing import Optional, List
from datetime import datetime
import logging

from app.services.use_case_ml_service import use_case_ml_service
from app.schemas.use_cases import (
    TrafficAnalysisRequest, TrafficAnalysisResult,
    SirenDetectionRequest, SirenDetectionResult,
    NoiseMappingRequest, NoiseMappingResult,
    IndustrialMonitoringRequest, IndustrialMonitoringResult,
    WildlifeMonitoringRequest, WildlifeMonitoringResult,
    UnifiedAnalysisRequest, UnifiedAnalysisResult,
    DashboardMetrics, HeatmapData, TimeSeriesData
)
from app.config import UseCaseType

router = APIRouter(prefix="/use-cases", tags=["use-cases"])

logger = logging.getLogger(__name__)


# Traffic Monitoring Endpoints
@router.post("/traffic/analyze", response_model=TrafficAnalysisResult)
async def analyze_traffic(
    device_id: str = Form(..., description="Device ID"),
    location: str = Form(..., description="Geographic location"),
    audio_file: UploadFile = File(..., description="Audio file for analysis"),
    metadata: Optional[str] = Form(None, description="Additional metadata as JSON string"),
    ml_service: use_case_ml_service = Depends(lambda: use_case_ml_service)
):
    """Analyze traffic patterns from audio data."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Parse metadata if provided
        import json
        parsed_metadata = json.loads(metadata) if metadata else None
        
        # Create request
        request = TrafficAnalysisRequest(
            device_id=device_id,
            location=location,
            audio_data=audio_data,
            metadata=parsed_metadata
        )
        
        # Perform analysis
        result = await ml_service.analyze_traffic(request)
        
        logger.info(f"Traffic analysis completed for device {device_id}: {result.event_type}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to analyze traffic: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to analyze traffic: {str(e)}")


# Siren Detection Endpoints
@router.post("/siren/detect", response_model=SirenDetectionResult)
async def detect_siren(
    device_id: str = Form(..., description="Device ID"),
    location: str = Form(..., description="Geographic location"),
    audio_file: UploadFile = File(..., description="Audio file for analysis"),
    emergency_priority: bool = Form(False, description="High priority emergency"),
    metadata: Optional[str] = Form(None, description="Additional metadata as JSON string"),
    ml_service: use_case_ml_service = Depends(lambda: use_case_ml_service)
):
    """Detect emergency sirens in audio data."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Parse metadata if provided
        import json
        parsed_metadata = json.loads(metadata) if metadata else None
        
        # Create request
        request = SirenDetectionRequest(
            device_id=device_id,
            location=location,
            audio_data=audio_data,
            emergency_priority=emergency_priority,
            metadata=parsed_metadata
        )
        
        # Perform detection
        result = await ml_service.detect_siren(request)
        
        logger.info(f"Siren detection completed for device {device_id}: {result.siren_detected}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to detect siren: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to detect siren: {str(e)}")


# Noise Mapping Endpoints
@router.post("/noise/analyze", response_model=NoiseMappingResult)
async def analyze_noise_mapping(
    device_id: str = Form(..., description="Device ID"),
    location: str = Form(..., description="Geographic location"),
    audio_file: UploadFile = File(..., description="Audio file for analysis"),
    measurement_duration_s: int = Form(300, ge=60, le=3600, description="Measurement duration in seconds"),
    calibration_data: Optional[str] = Form(None, description="Calibration data as JSON string"),
    metadata: Optional[str] = Form(None, description="Additional metadata as JSON string"),
    ml_service: use_case_ml_service = Depends(lambda: use_case_ml_service)
):
    """Analyze noise levels for urban mapping."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Parse metadata if provided
        import json
        parsed_metadata = json.loads(metadata) if metadata else None
        parsed_calibration = json.loads(calibration_data) if calibration_data else None
        
        # Create request
        request = NoiseMappingRequest(
            device_id=device_id,
            location=location,
            audio_data=audio_data,
            measurement_duration_s=measurement_duration_s,
            calibration_data=parsed_calibration,
            metadata=parsed_metadata
        )
        
        # Perform analysis
        result = await ml_service.analyze_noise_mapping(request)
        
        logger.info(f"Noise mapping analysis completed for device {device_id}: {result.noise_level}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to analyze noise mapping: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to analyze noise mapping: {str(e)}")


# Industrial Monitoring Endpoints
@router.post("/industrial/analyze", response_model=IndustrialMonitoringResult)
async def analyze_industrial_monitoring(
    device_id: str = Form(..., description="Device ID"),
    machinery_id: str = Form(..., description="Machinery ID"),
    location: str = Form(..., description="Geographic location"),
    audio_file: UploadFile = File(..., description="Audio file for analysis"),
    machinery_type: str = Form(..., description="Type of machinery"),
    operating_conditions: Optional[str] = Form(None, description="Operating conditions as JSON string"),
    metadata: Optional[str] = Form(None, description="Additional metadata as JSON string"),
    ml_service: use_case_ml_service = Depends(lambda: use_case_ml_service)
):
    """Analyze industrial machinery for anomalies."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Parse metadata if provided
        import json
        parsed_metadata = json.loads(metadata) if metadata else None
        parsed_conditions = json.loads(operating_conditions) if operating_conditions else None
        
        # Create request
        request = IndustrialMonitoringRequest(
            device_id=device_id,
            machinery_id=machinery_id,
            location=location,
            audio_data=audio_data,
            machinery_type=machinery_type,
            operating_conditions=parsed_conditions,
            metadata=parsed_metadata
        )
        
        # Perform analysis
        result = await ml_service.analyze_industrial_monitoring(request)
        
        logger.info(f"Industrial monitoring analysis completed for device {device_id}: {result.anomaly_detected}")
        return result
        
    except Exception as e:
        logger.error(f"Failed to analyze industrial monitoring: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to analyze industrial monitoring: {str(e)}")


# Wildlife Monitoring Endpoints
@router.post("/wildlife/analyze", response_model=WildlifeMonitoringResult)
async def analyze_wildlife_monitoring(
    device_id: str = Form(..., description="Device ID"),
    location: str = Form(..., description="Geographic location"),
    audio_file: UploadFile = File(..., description="Audio file for analysis"),
    habitat_type: str = Form(..., description="Type of habitat"),
    season: Optional[str] = Form(None, description="Season of the year"),
    time_of_day: Optional[str] = Form(None, description="Time of day"),
    metadata: Optional[str] = Form(None, description="Additional metadata as JSON string"),
    ml_service: use_case_ml_service = Depends(lambda: use_case_ml_service)
):
    """Analyze wildlife sounds for species identification."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Parse metadata if provided
        import json
        parsed_metadata = json.loads(metadata) if metadata else None
        
        # Create request
        request = WildlifeMonitoringRequest(
            device_id=device_id,
            location=location,
            audio_data=audio_data,
            habitat_type=habitat_type,
            season=season,
            time_of_day=time_of_day,
            metadata=parsed_metadata
        )
        
        # Perform analysis
        result = await ml_service.analyze_wildlife_monitoring(request)
        
        logger.info(f"Wildlife monitoring analysis completed for device {device_id}: {len(result.species_detected)} species")
        return result
        
    except Exception as e:
        logger.error(f"Failed to analyze wildlife monitoring: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to analyze wildlife monitoring: {str(e)}")


# Unified Analysis Endpoints
@router.post("/unified/analyze", response_model=UnifiedAnalysisResult)
async def analyze_unified(
    device_id: str = Form(..., description="Device ID"),
    location: str = Form(..., description="Geographic location"),
    audio_file: UploadFile = File(..., description="Audio file for analysis"),
    use_cases: str = Form(..., description="Comma-separated list of use cases"),
    priority: int = Form(1, ge=1, le=5, description="Analysis priority"),
    metadata: Optional[str] = Form(None, description="Additional metadata as JSON string"),
    ml_service: use_case_ml_service = Depends(lambda: use_case_ml_service)
):
    """Perform unified analysis across multiple use cases."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Parse use cases
        use_case_list = [UseCaseType(uc.strip()) for uc in use_cases.split(',')]
        
        # Parse metadata if provided
        import json
        parsed_metadata = json.loads(metadata) if metadata else None
        
        # Create request
        request = UnifiedAnalysisRequest(
            device_id=device_id,
            location=location,
            audio_data=audio_data,
            use_cases=use_case_list,
            priority=priority,
            metadata=parsed_metadata
        )
        
        # Perform analysis
        result = await ml_service.analyze_unified(request)
        
        logger.info(f"Unified analysis completed for device {device_id}: {len(result.results)} use cases")
        return result
        
    except Exception as e:
        logger.error(f"Failed to perform unified analysis: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Failed to perform unified analysis: {str(e)}")


# Dashboard and Visualization Endpoints
@router.get("/dashboard/metrics", response_model=DashboardMetrics)
async def get_dashboard_metrics(
    hours: int = Query(24, ge=1, le=168, description="Time range in hours")
):
    """Get dashboard metrics for visualization."""
    try:
        # Mock implementation - in production, this would query the database
        from datetime import datetime, timedelta
        
        return DashboardMetrics(
            timestamp=datetime.utcnow(),
            device_count=150,
            active_devices=142,
            events_processed=15420,
            alerts_generated=23,
            system_health=0.95,
            performance_metrics={
                "avg_latency_ms": 85.2,
                "throughput_rps": 95.8,
                "error_rate": 0.02,
                "cpu_usage": 0.65,
                "memory_usage": 0.72
            },
            cost_metrics={
                "cost_per_event": 0.008,
                "daily_cost": 123.45,
                "monthly_cost": 3703.50,
                "cost_trend": 0.05
            }
        )
        
    except Exception as e:
        logger.error(f"Failed to get dashboard metrics: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get dashboard metrics")


@router.get("/heatmap/data", response_model=List[HeatmapData])
async def get_heatmap_data(
    use_case: UseCaseType = Query(..., description="Use case type"),
    hours: int = Query(24, ge=1, le=168, description="Time range in hours")
):
    """Get heatmap data for spatial visualization."""
    try:
        # Mock implementation - in production, this would query the database
        import random
        from datetime import datetime, timedelta
        
        locations = ["Downtown", "Airport", "Industrial Zone", "Residential", "Park"]
        categories = ["traffic", "noise", "siren", "anomaly", "wildlife"]
        
        data = []
        for i in range(20):
            data.append(HeatmapData(
                location=random.choice(locations),
                timestamp=datetime.utcnow() - timedelta(hours=random.randint(0, hours)),
                value=random.uniform(0.0, 1.0),
                category=random.choice(categories),
                confidence=random.uniform(0.7, 1.0)
            ))
        
        return data
        
    except Exception as e:
        logger.error(f"Failed to get heatmap data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get heatmap data")


@router.get("/timeseries/data", response_model=List[TimeSeriesData])
async def get_timeseries_data(
    device_id: str = Query(..., description="Device ID"),
    use_case: UseCaseType = Query(..., description="Use case type"),
    hours: int = Query(24, ge=1, le=168, description="Time range in hours")
):
    """Get time series data for temporal analysis."""
    try:
        # Mock implementation - in production, this would query the database
        import random
        from datetime import datetime, timedelta
        
        categories = ["traffic_density", "noise_level", "siren_detection", "anomaly_score", "biodiversity"]
        
        data = []
        for i in range(100):
            data.append(TimeSeriesData(
                timestamp=datetime.utcnow() - timedelta(minutes=random.randint(0, hours * 60)),
                value=random.uniform(0.0, 1.0),
                category=random.choice(categories),
                device_id=device_id,
                metadata={"confidence": random.uniform(0.7, 1.0)}
            ))
        
        return sorted(data, key=lambda x: x.timestamp)
        
    except Exception as e:
        logger.error(f"Failed to get timeseries data: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get timeseries data")


# Use Case Status Endpoints
@router.get("/status")
async def get_use_case_status():
    """Get status of all use cases."""
    try:
        return {
            "enabled_use_cases": [uc.value for uc in UseCaseType],
            "traffic_monitoring": {
                "enabled": True,
                "model_loaded": True,
                "last_analysis": datetime.utcnow().isoformat()
            },
            "siren_detection": {
                "enabled": True,
                "model_loaded": True,
                "last_analysis": datetime.utcnow().isoformat()
            },
            "noise_mapping": {
                "enabled": True,
                "model_loaded": True,
                "last_analysis": datetime.utcnow().isoformat()
            },
            "industrial_monitoring": {
                "enabled": True,
                "model_loaded": True,
                "last_analysis": datetime.utcnow().isoformat()
            },
            "wildlife_monitoring": {
                "enabled": True,
                "model_loaded": True,
                "last_analysis": datetime.utcnow().isoformat()
            }
        }
        
    except Exception as e:
        logger.error(f"Failed to get use case status: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get use case status")
