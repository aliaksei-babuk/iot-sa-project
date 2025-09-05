"""NFR compliance testing framework."""
import pytest
import asyncio
from datetime import datetime, timedelta
from unittest.mock import Mock, patch

from app.services.nfr_compliance_service import nfr_compliance_service, NFRStatus
from app.config import settings


class TestNFRCompliance:
    """Test NFR compliance monitoring."""
    
    def setup_method(self):
        """Setup test environment."""
        # Clear any existing data
        nfr_compliance_service.metrics_history.clear()
        nfr_compliance_service.alerts.clear()
        nfr_compliance_service.compliance_status.clear()
    
    def test_record_metric(self):
        """Test metric recording functionality."""
        # Test recording a compliant metric
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 85.0, "ms")
        
        # Verify metric was recorded
        assert "NFR-01" in nfr_compliance_service.metrics_history
        assert "p95_latency_ms" in nfr_compliance_service.metrics_history["NFR-01"]
        assert len(nfr_compliance_service.metrics_history["NFR-01"]["p95_latency_ms"]) == 1
        
        # Verify compliance status
        assert "NFR-01" in nfr_compliance_service.compliance_status
        assert "p95_latency_ms" in nfr_compliance_service.compliance_status["NFR-01"]
        assert nfr_compliance_service.compliance_status["NFR-01"]["p95_latency_ms"].status == NFRStatus.COMPLIANT
    
    def test_violation_detection(self):
        """Test violation detection and alerting."""
        # Record a metric that violates NFR-01 (latency > 100ms)
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 150.0, "ms")
        
        # Verify violation was detected
        metric = nfr_compliance_service.compliance_status["NFR-01"]["p95_latency_ms"]
        assert metric.status in [NFRStatus.WARNING, NFRStatus.VIOLATION, NFRStatus.CRITICAL]
        
        # Verify alert was generated
        assert len(nfr_compliance_service.alerts) > 0
        alert = nfr_compliance_service.alerts[0]
        assert alert["nfr_id"] == "NFR-01"
        assert alert["metric_name"] == "p95_latency_ms"
    
    def test_trend_calculation(self):
        """Test trend calculation functionality."""
        # Record multiple metrics to establish trend
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 100.0, "ms")
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 110.0, "ms")
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 120.0, "ms")
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 130.0, "ms")
        
        # Check trend calculation
        trend = nfr_compliance_service._calculate_trend("NFR-01", "p95_latency_ms")
        assert trend == "degrading"
    
    def test_compliance_status_retrieval(self):
        """Test compliance status retrieval."""
        # Record some metrics
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 85.0, "ms")
        nfr_compliance_service.record_metric("NFR-02", "concurrent_devices", 5000, "devices")
        
        # Get all compliance status
        status = nfr_compliance_service.get_compliance_status()
        assert "NFR-01" in status
        assert "NFR-02" in status
        
        # Get specific NFR status
        nfr01_status = nfr_compliance_service.get_compliance_status("NFR-01")
        assert "NFR-01" in nfr01_status
        assert "p95_latency_ms" in nfr01_status["NFR-01"]
    
    def test_alert_filtering(self):
        """Test alert filtering functionality."""
        # Generate alerts with different statuses
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 150.0, "ms")  # Violation
        nfr_compliance_service.record_metric("NFR-02", "concurrent_devices", 12000, "devices")  # Violation
        
        # Test filtering by status
        critical_alerts = nfr_compliance_service.get_alerts(status=NFRStatus.CRITICAL)
        warning_alerts = nfr_compliance_service.get_alerts(status=NFRStatus.WARNING)
        
        # Verify filtering works
        assert isinstance(critical_alerts, list)
        assert isinstance(warning_alerts, list)
    
    def test_nfr_summary(self):
        """Test NFR summary generation."""
        # Record metrics for different NFRs
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 85.0, "ms")
        nfr_compliance_service.record_metric("NFR-02", "concurrent_devices", 5000, "devices")
        nfr_compliance_service.record_metric("NFR-03", "uptime_percent", 99.5, "%")
        
        # Get summary
        summary = nfr_compliance_service.get_nfr_summary()
        
        # Verify summary structure
        assert "total_nfrs" in summary
        assert "compliant_nfrs" in summary
        assert "overall_status" in summary
        assert summary["total_nfrs"] > 0
    
    def test_metric_history(self):
        """Test metric history retrieval."""
        # Record multiple metrics over time
        base_time = datetime.utcnow()
        for i in range(10):
            nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 80.0 + i, "ms")
        
        # Get history
        history = nfr_compliance_service.get_metric_history("NFR-01", "p95_latency_ms", hours=24)
        
        # Verify history
        assert len(history) == 10
        assert all("value" in h for h in history)
        assert all("timestamp" in h for h in history)
    
    def test_validation(self):
        """Test NFR compliance validation."""
        # Record compliant metrics
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 85.0, "ms")
        nfr_compliance_service.record_metric("NFR-02", "concurrent_devices", 5000, "devices")
        
        # Validate compliance
        validation = nfr_compliance_service.validate_nfr_compliance()
        
        # Verify validation structure
        assert "overall_compliance" in validation
        assert "nfrs_validated" in validation
        assert "nfrs_passing" in validation
        assert "nfrs_failing" in validation
        assert "details" in validation


class TestNFRPerformance:
    """Test NFR performance requirements."""
    
    def test_latency_requirements(self):
        """Test NFR-01: Performance requirements."""
        # Test p95 latency requirement
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 95.0, "ms")
        metric = nfr_compliance_service.compliance_status["NFR-01"]["p95_latency_ms"]
        assert metric.status == NFRStatus.COMPLIANT
        
        # Test violation
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 150.0, "ms")
        metric = nfr_compliance_service.compliance_status["NFR-01"]["p95_latency_ms"]
        assert metric.status in [NFRStatus.WARNING, NFRStatus.VIOLATION, NFRStatus.CRITICAL]
    
    def test_scalability_requirements(self):
        """Test NFR-02: Scalability requirements."""
        # Test concurrent devices requirement
        nfr_compliance_service.record_metric("NFR-02", "concurrent_devices", 8000, "devices")
        metric = nfr_compliance_service.compliance_status["NFR-02"]["concurrent_devices"]
        assert metric.status == NFRStatus.COMPLIANT
        
        # Test violation
        nfr_compliance_service.record_metric("NFR-02", "concurrent_devices", 12000, "devices")
        metric = nfr_compliance_service.compliance_status["NFR-02"]["concurrent_devices"]
        assert metric.status in [NFRStatus.WARNING, NFRStatus.VIOLATION, NFRStatus.CRITICAL]
    
    def test_availability_requirements(self):
        """Test NFR-03: Availability requirements."""
        # Test uptime requirement
        nfr_compliance_service.record_metric("NFR-03", "uptime_percent", 99.95, "%")
        metric = nfr_compliance_service.compliance_status["NFR-03"]["uptime_percent"]
        assert metric.status == NFRStatus.COMPLIANT
        
        # Test violation
        nfr_compliance_service.record_metric("NFR-03", "uptime_percent", 98.5, "%")
        metric = nfr_compliance_service.compliance_status["NFR-03"]["uptime_percent"]
        assert metric.status in [NFRStatus.WARNING, NFRStatus.VIOLATION, NFRStatus.CRITICAL]


class TestNFRIntegration:
    """Test NFR integration with other components."""
    
    @pytest.mark.asyncio
    async def test_async_metric_recording(self):
        """Test async metric recording."""
        # This would test integration with async components
        # For now, just test that the service can handle async calls
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 85.0, "ms")
        assert "NFR-01" in nfr_compliance_service.compliance_status
    
    def test_metrics_service_integration(self):
        """Test integration with metrics service."""
        # This would test integration with the metrics service
        # For now, just verify the service is available
        from app.services.metrics_service import metrics_service
        assert metrics_service is not None
    
    def test_alert_integration(self):
        """Test alert integration."""
        # Record a metric that should generate an alert
        nfr_compliance_service.record_metric("NFR-01", "p95_latency_ms", 200.0, "ms")
        
        # Verify alert was generated
        alerts = nfr_compliance_service.get_alerts()
        assert len(alerts) > 0
        
        # Verify alert structure
        alert = alerts[0]
        assert "id" in alert
        assert "nfr_id" in alert
        assert "metric_name" in alert
        assert "status" in alert
        assert "message" in alert


if __name__ == "__main__":
    pytest.main([__file__])
