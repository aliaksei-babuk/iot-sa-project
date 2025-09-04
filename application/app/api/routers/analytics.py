"""Analytics and ML processing API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
from typing import Optional, Dict, Any
import logging

from app.services.ml_service import MLService
from app.services.telemetry_service import TelemetryService
from app.services.alert_service import AlertService
from app.schemas.telemetry import ProcessingResult
from app.schemas.alert import AlertCreate, AlertType, AlertSeverity
from app.api.dependencies import get_ml_service, get_telemetry_service, get_alert_service

router = APIRouter(prefix="/analytics", tags=["analytics"])

logger = logging.getLogger(__name__)


@router.post("/process-audio", response_model=ProcessingResult)
async def process_audio_file(
    audio_file: UploadFile = File(..., description="Audio file to process"),
    device_id: str = Form(..., description="Device ID"),
    ml_service: MLService = Depends(get_ml_service)
):
    """Process audio file for drone detection."""
    try:
        # Validate file type
        if not audio_file.content_type.startswith('audio/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an audio file"
            )
        
        # Read audio data
        audio_data = await audio_file.read()
        
        # Process with ML service
        result = ml_service.process_audio_data(audio_data, 22050)  # Default sample rate
        
        logger.info(f"Audio processing completed for device {device_id}: "
                   f"drone_detected={result.is_drone_detected}, "
                   f"confidence={result.confidence_score}")
        
        return result
        
    except Exception as e:
        logger.error(f"Failed to process audio file: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to process audio file")


@router.get("/model-info")
async def get_model_info(
    ml_service: MLService = Depends(get_ml_service)
):
    """Get information about loaded ML models."""
    try:
        info = ml_service.get_model_info()
        return info
    except Exception as e:
        logger.error(f"Failed to get model info: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get model info")


@router.post("/trigger-processing")
async def trigger_audio_processing(
    device_id: Optional[str] = Query(None, description="Process audio for specific device"),
    telemetry_service: TelemetryService = Depends(get_telemetry_service),
    alert_service: AlertService = Depends(get_alert_service),
    ml_service: MLService = Depends(get_ml_service)
):
    """Manually trigger audio processing for unprocessed data."""
    try:
        # Get unprocessed audio data
        unprocessed_data = telemetry_service.get_unprocessed_audio_data(limit=10)
        
        if device_id:
            # Filter by device if specified
            unprocessed_data = [d for d in unprocessed_data if d.device_id == device_id]
        
        processed_count = 0
        alerts_created = 0
        
        for data in unprocessed_data:
            try:
                # Get audio file path
                audio_path = telemetry_service.get_audio_file_path(data.id)
                if not audio_path:
                    continue
                
                # Process audio with ML service
                result = ml_service.process_audio_file(audio_path)
                
                # Update telemetry data with results
                telemetry_service.update_processing_result(data.id, result)
                processed_count += 1
                
                # Create alert if drone detected
                if result.is_drone_detected and result.confidence_score > 0.7:
                    alert_data = AlertCreate(
                        device_id=data.device_id,
                        alert_type=AlertType.DRONE_DETECTED,
                        severity=AlertSeverity.HIGH if result.confidence_score > 0.9 else AlertSeverity.MEDIUM,
                        message=f"Drone detected with confidence {result.confidence_score:.2f}",
                        confidence_score=result.confidence_score,
                        metadata={
                            "telemetry_id": data.id,
                            "classification": result.classification,
                            "processing_time": result.processing_time
                        }
                    )
                    alert_service.create_alert(alert_data)
                    alerts_created += 1
                
            except Exception as e:
                logger.error(f"Failed to process audio data {data.id}: {e}")
                continue
        
        return {
            "message": "Audio processing triggered",
            "processed_count": processed_count,
            "alerts_created": alerts_created,
            "total_unprocessed": len(unprocessed_data)
        }
        
    except Exception as e:
        logger.error(f"Failed to trigger audio processing: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to trigger processing")


@router.get("/detection-stats")
async def get_detection_stats(
    hours: int = Query(24, ge=1, le=168, description="Time range in hours"),
    telemetry_service: TelemetryService = Depends(get_telemetry_service)
):
    """Get drone detection statistics."""
    try:
        from datetime import datetime, timedelta
        
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=hours)
        
        # Get processed audio data in time range
        data, total = telemetry_service.get_telemetry_data(
            device_id="",  # Get all devices
            start_time=start_time,
            end_time=end_time,
            page=1,
            page_size=1000
        )
        
        # Filter for processed audio data
        processed_audio = [d for d in data if d.data_type == "audio" and d.processed and d.processing_result]
        
        # Calculate statistics
        total_processed = len(processed_audio)
        drone_detections = sum(1 for d in processed_audio 
                             if d.processing_result and d.processing_result.get("is_drone_detected", False))
        
        high_confidence_detections = sum(1 for d in processed_audio 
                                       if d.processing_result and 
                                       d.processing_result.get("is_drone_detected", False) and
                                       d.processing_result.get("confidence_score", 0) > 0.9)
        
        avg_confidence = 0
        if drone_detections > 0:
            confidences = [d.processing_result.get("confidence_score", 0) 
                          for d in processed_audio 
                          if d.processing_result and d.processing_result.get("is_drone_detected", False)]
            avg_confidence = sum(confidences) / len(confidences)
        
        # Classification breakdown
        classifications = {}
        for d in processed_audio:
            if d.processing_result and "classification" in d.processing_result:
                classification = d.processing_result["classification"]
                classifications[classification] = classifications.get(classification, 0) + 1
        
        return {
            "time_range_hours": hours,
            "total_processed": total_processed,
            "drone_detections": drone_detections,
            "high_confidence_detections": high_confidence_detections,
            "detection_rate": drone_detections / total_processed if total_processed > 0 else 0,
            "avg_confidence": round(avg_confidence, 3),
            "classifications": classifications
        }
        
    except Exception as e:
        logger.error(f"Failed to get detection stats: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get detection stats")


@router.get("/health")
async def get_analytics_health(
    ml_service: MLService = Depends(get_ml_service)
):
    """Get analytics service health status."""
    try:
        model_info = ml_service.get_model_info()
        
        # Check if models are loaded
        drone_model_loaded = model_info["drone_detection_model"]["loaded"]
        classifier_loaded = model_info["sound_classifier"]["loaded"]
        
        health_status = "healthy"
        if not drone_model_loaded or not classifier_loaded:
            health_status = "degraded"
        
        return {
            "status": health_status,
            "models": model_info,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get analytics health: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }
