"""Metrics and monitoring service."""
import time
import logging
from typing import Dict, Any, Optional
from prometheus_client import Counter, Histogram, Gauge, Info, generate_latest, CONTENT_TYPE_LATEST
from fastapi import Response

logger = logging.getLogger(__name__)


class MetricsService:
    """Service for collecting and exposing metrics."""
    
    def __init__(self):
        self._setup_metrics()
    
    def _setup_metrics(self):
        """Setup Prometheus metrics."""
        # Application info
        self.app_info = Info('iot_sound_detection_app', 'Application information')
        self.app_info.info({
            'version': '1.0.0',
            'name': 'IoT Sound Detection POC'
        })
        
        # Request metrics
        self.request_count = Counter(
            'http_requests_total',
            'Total HTTP requests',
            ['method', 'endpoint', 'status_code']
        )
        
        self.request_duration = Histogram(
            'http_request_duration_seconds',
            'HTTP request duration in seconds',
            ['method', 'endpoint']
        )
        
        # Device metrics
        self.device_count = Gauge(
            'devices_total',
            'Total number of registered devices'
        )
        
        self.device_online_count = Gauge(
            'devices_online_total',
            'Number of online devices'
        )
        
        self.device_offline_count = Gauge(
            'devices_offline_total',
            'Number of offline devices'
        )
        
        # Telemetry metrics
        self.telemetry_count = Counter(
            'telemetry_data_total',
            'Total telemetry data received',
            ['device_id', 'data_type']
        )
        
        self.audio_processing_duration = Histogram(
            'audio_processing_duration_seconds',
            'Audio processing duration in seconds',
            ['device_id']
        )
        
        # ML metrics
        self.drone_detections = Counter(
            'drone_detections_total',
            'Total drone detections',
            ['device_id', 'confidence_level']
        )
        
        self.ml_processing_errors = Counter(
            'ml_processing_errors_total',
            'Total ML processing errors',
            ['error_type']
        )
        
        # Alert metrics
        self.alerts_total = Counter(
            'alerts_total',
            'Total alerts created',
            ['alert_type', 'severity']
        )
        
        self.active_alerts = Gauge(
            'active_alerts_total',
            'Number of active alerts',
            ['severity']
        )
        
        # MQTT metrics
        self.mqtt_messages_sent = Counter(
            'mqtt_messages_sent_total',
            'Total MQTT messages sent',
            ['topic']
        )
        
        self.mqtt_messages_received = Counter(
            'mqtt_messages_received_total',
            'Total MQTT messages received',
            ['topic']
        )
        
        # Database metrics
        self.database_connections = Gauge(
            'database_connections_active',
            'Active database connections'
        )
        
        self.database_query_duration = Histogram(
            'database_query_duration_seconds',
            'Database query duration in seconds',
            ['operation']
        )
        
        logger.info("Metrics service initialized")
    
    def record_request(self, method: str, endpoint: str, status_code: int, duration: float):
        """Record HTTP request metrics."""
        self.request_count.labels(method=method, endpoint=endpoint, status_code=status_code).inc()
        self.request_duration.labels(method=method, endpoint=endpoint).observe(duration)
    
    def update_device_metrics(self, total: int, online: int, offline: int):
        """Update device-related metrics."""
        self.device_count.set(total)
        self.device_online_count.set(online)
        self.device_offline_count.set(offline)
    
    def record_telemetry(self, device_id: str, data_type: str):
        """Record telemetry data metrics."""
        self.telemetry_count.labels(device_id=device_id, data_type=data_type).inc()
    
    def record_audio_processing(self, device_id: str, duration: float):
        """Record audio processing metrics."""
        self.audio_processing_duration.labels(device_id=device_id).observe(duration)
    
    def record_drone_detection(self, device_id: str, confidence: float):
        """Record drone detection metrics."""
        confidence_level = "high" if confidence > 0.9 else "medium" if confidence > 0.7 else "low"
        self.drone_detections.labels(device_id=device_id, confidence_level=confidence_level).inc()
    
    def record_ml_error(self, error_type: str):
        """Record ML processing error."""
        self.ml_processing_errors.labels(error_type=error_type).inc()
    
    def record_alert(self, alert_type: str, severity: str):
        """Record alert creation."""
        self.alerts_total.labels(alert_type=alert_type, severity=severity).inc()
    
    def update_active_alerts(self, alerts_by_severity: Dict[str, int]):
        """Update active alerts metrics."""
        for severity, count in alerts_by_severity.items():
            self.active_alerts.labels(severity=severity).set(count)
    
    def record_mqtt_message_sent(self, topic: str):
        """Record MQTT message sent."""
        self.mqtt_messages_sent.labels(topic=topic).inc()
    
    def record_mqtt_message_received(self, topic: str):
        """Record MQTT message received."""
        self.mqtt_messages_received.labels(topic=topic).inc()
    
    def record_database_operation(self, operation: str, duration: float):
        """Record database operation metrics."""
        self.database_query_duration.labels(operation=operation).observe(duration)
    
    def update_database_connections(self, count: int):
        """Update database connections metric."""
        self.database_connections.set(count)
    
    def get_metrics(self) -> str:
        """Get metrics in Prometheus format."""
        return generate_latest()
    
    def get_metrics_response(self) -> Response:
        """Get metrics as FastAPI response."""
        return Response(
            content=generate_latest(),
            media_type=CONTENT_TYPE_LATEST
        )


# Global metrics service instance
metrics_service = MetricsService()
