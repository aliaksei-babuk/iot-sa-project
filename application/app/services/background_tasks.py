"""Background task processing service."""
import asyncio
import logging
from typing import List
from datetime import datetime, timedelta
import threading
import time

from app.services.database import db_service
from app.services.telemetry_service import TelemetryService
from app.services.alert_service import AlertService
from app.services.ml_service import ml_service
from app.schemas.alert import AlertCreate, AlertType, AlertSeverity

logger = logging.getLogger(__name__)


class BackgroundTaskService:
    """Service for running background tasks."""
    
    def __init__(self):
        self.running = False
        self.tasks = []
        self.thread = None
    
    def start(self):
        """Start background task processing."""
        if not self.running:
            self.running = True
            self.thread = threading.Thread(target=self._run_tasks, daemon=True)
            self.thread.start()
            logger.info("Background task service started")
    
    def stop(self):
        """Stop background task processing."""
        self.running = False
        if self.thread:
            self.thread.join(timeout=5)
        logger.info("Background task service stopped")
    
    def _run_tasks(self):
        """Main task loop."""
        while self.running:
            try:
                # Process audio data
                self._process_audio_data()
                
                # Check for offline devices
                self._check_offline_devices()
                
                # Cleanup old data
                self._cleanup_old_data()
                
                # Sleep before next iteration
                time.sleep(10)  # Run every 10 seconds
                
            except Exception as e:
                logger.error(f"Error in background task loop: {e}")
                time.sleep(5)  # Wait before retrying
    
    def _process_audio_data(self):
        """Process unprocessed audio data."""
        try:
            session = db_service.get_session()
            try:
                telemetry_service = TelemetryService(session)
                alert_service = AlertService(session)
                
                # Get unprocessed audio data
                unprocessed_data = telemetry_service.get_unprocessed_audio_data(limit=5)
                
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
                        
                        logger.info(f"Processed audio data {data.id}: drone_detected={result.is_drone_detected}")
                        
                    except Exception as e:
                        logger.error(f"Failed to process audio data {data.id}: {e}")
                        continue
                
            finally:
                db_service.close_session(session)
                
        except Exception as e:
            logger.error(f"Error in audio processing task: {e}")
    
    def _check_offline_devices(self):
        """Check for offline devices and create alerts."""
        try:
            session = db_service.get_session()
            try:
                from app.services.device_service import DeviceService
                from app.schemas.device import DeviceStatus
                
                device_service = DeviceService(session)
                alert_service = AlertService(session)
                
                # Get devices that haven't been seen for 1 hour
                offline_devices = device_service.get_offline_devices(hours=1)
                
                for device in offline_devices:
                    # Update device status
                    device_service.update_device_status(device.device_id, DeviceStatus.OFFLINE)
                    
                    # Create alert
                    alert_data = AlertCreate(
                        device_id=device.device_id,
                        alert_type=AlertType.DEVICE_OFFLINE,
                        severity=AlertSeverity.MEDIUM,
                        message=f"Device {device.name} has been offline for more than 1 hour",
                        metadata={
                            "last_seen": device.last_seen.isoformat(),
                            "device_type": device.device_type
                        }
                    )
                    alert_service.create_alert(alert_data)
                    
                    logger.info(f"Device {device.device_id} marked as offline")
                
            finally:
                db_service.close_session(session)
                
        except Exception as e:
            logger.error(f"Error in offline device check: {e}")
    
    def _cleanup_old_data(self):
        """Clean up old data to maintain database performance."""
        try:
            session = db_service.get_session()
            try:
                telemetry_service = TelemetryService(session)
                alert_service = AlertService(session)
                
                # Clean up old telemetry data (older than 30 days)
                telemetry_cleaned = telemetry_service.cleanup_old_data(days=30)
                
                # Clean up old resolved alerts (older than 7 days)
                alerts_cleaned = alert_service.cleanup_resolved_alerts(days=7)
                
                if telemetry_cleaned > 0 or alerts_cleaned > 0:
                    logger.info(f"Cleaned up {telemetry_cleaned} telemetry records and {alerts_cleaned} alerts")
                
            finally:
                db_service.close_session(session)
                
        except Exception as e:
            logger.error(f"Error in data cleanup task: {e}")
    
    def add_task(self, task_func, *args, **kwargs):
        """Add a custom task to the task queue."""
        self.tasks.append((task_func, args, kwargs))
    
    def run_custom_tasks(self):
        """Run custom tasks."""
        for task_func, args, kwargs in self.tasks:
            try:
                task_func(*args, **kwargs)
            except Exception as e:
                logger.error(f"Error running custom task {task_func.__name__}: {e}")


# Global background task service instance
background_tasks = BackgroundTaskService()
