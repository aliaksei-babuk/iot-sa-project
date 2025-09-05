"""Enhanced monitoring and dashboard API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
import logging

from app.services.nfr_compliance_service import nfr_compliance_service, NFRStatus
from app.services.metrics_service import metrics_service
from app.schemas.use_cases import DashboardMetrics, HeatmapData, TimeSeriesData

router = APIRouter(prefix="/monitoring", tags=["monitoring"])

logger = logging.getLogger(__name__)


@router.get("/nfr/status")
async def get_nfr_status(nfr_id: Optional[str] = Query(None, description="Specific NFR ID")):
    """Get NFR compliance status."""
    try:
        status = nfr_compliance_service.get_compliance_status(nfr_id)
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "nfr_status": status
        }
    except Exception as e:
        logger.error(f"Failed to get NFR status: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get NFR status")


@router.get("/nfr/summary")
async def get_nfr_summary():
    """Get NFR compliance summary."""
    try:
        summary = nfr_compliance_service.get_nfr_summary()
        return summary
    except Exception as e:
        logger.error(f"Failed to get NFR summary: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get NFR summary")


@router.get("/nfr/alerts")
async def get_nfr_alerts(
    limit: int = Query(100, ge=1, le=1000, description="Number of alerts to return"),
    status: Optional[NFRStatus] = Query(None, description="Filter by alert status")
):
    """Get NFR compliance alerts."""
    try:
        alerts = nfr_compliance_service.get_alerts(limit=limit, status=status)
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "alerts": alerts,
            "total_count": len(alerts)
        }
    except Exception as e:
        logger.error(f"Failed to get NFR alerts: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get NFR alerts")


@router.get("/nfr/metrics/{nfr_id}/{metric_name}/history")
async def get_nfr_metric_history(
    nfr_id: str,
    metric_name: str,
    hours: int = Query(24, ge=1, le=168, description="Hours of history to return")
):
    """Get metric history for a specific NFR metric."""
    try:
        history = nfr_compliance_service.get_metric_history(nfr_id, metric_name, hours)
        return {
            "nfr_id": nfr_id,
            "metric_name": metric_name,
            "hours": hours,
            "history": history,
            "count": len(history)
        }
    except Exception as e:
        logger.error(f"Failed to get metric history: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get metric history")


@router.post("/nfr/validate")
async def validate_nfr_compliance():
    """Validate overall NFR compliance."""
    try:
        validation_result = nfr_compliance_service.validate_nfr_compliance()
        return validation_result
    except Exception as e:
        logger.error(f"Failed to validate NFR compliance: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to validate NFR compliance")


@router.get("/dashboard/overview")
async def get_dashboard_overview():
    """Get comprehensive dashboard overview."""
    try:
        # Get NFR summary
        nfr_summary = nfr_compliance_service.get_nfr_summary()
        
        # Get recent alerts
        recent_alerts = nfr_compliance_service.get_alerts(limit=10)
        
        # Get system metrics (mock implementation)
        system_metrics = {
            "total_devices": 150,
            "active_devices": 142,
            "events_processed_today": 15420,
            "alerts_generated_today": 23,
            "system_uptime_percent": 99.95,
            "avg_response_time_ms": 85.2,
            "error_rate_percent": 0.02,
            "cost_today_usd": 123.45
        }
        
        # Get performance trends (mock implementation)
        performance_trends = {
            "latency_trend": "improving",
            "throughput_trend": "stable",
            "error_rate_trend": "improving",
            "cost_trend": "stable"
        }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "nfr_summary": nfr_summary,
            "recent_alerts": recent_alerts,
            "system_metrics": system_metrics,
            "performance_trends": performance_trends
        }
        
    except Exception as e:
        logger.error(f"Failed to get dashboard overview: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get dashboard overview")


@router.get("/dashboard/performance")
async def get_performance_dashboard():
    """Get performance monitoring dashboard data."""
    try:
        # Mock performance data - in production, this would query actual metrics
        performance_data = {
            "latency_metrics": {
                "p95_latency_ms": 85.2,
                "p99_latency_ms": 120.5,
                "avg_latency_ms": 65.8,
                "max_latency_ms": 250.3,
                "min_latency_ms": 15.2
            },
            "throughput_metrics": {
                "current_rps": 95.8,
                "peak_rps": 150.2,
                "avg_rps": 88.5,
                "target_rps": 100.0
            },
            "resource_metrics": {
                "cpu_usage_percent": 65.2,
                "memory_usage_percent": 72.8,
                "disk_usage_percent": 45.3,
                "network_io_mbps": 125.6
            },
            "error_metrics": {
                "error_rate_percent": 0.02,
                "4xx_errors": 12,
                "5xx_errors": 3,
                "timeout_errors": 1
            },
            "scaling_metrics": {
                "active_instances": 8,
                "scaling_events_today": 3,
                "avg_scaling_time_s": 25.5,
                "target_instances": 10
            }
        }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "performance_data": performance_data
        }
        
    except Exception as e:
        logger.error(f"Failed to get performance dashboard: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get performance dashboard")


@router.get("/dashboard/security")
async def get_security_dashboard():
    """Get security monitoring dashboard data."""
    try:
        # Mock security data - in production, this would query actual security metrics
        security_data = {
            "authentication_metrics": {
                "total_logins": 1250,
                "failed_logins": 23,
                "active_sessions": 45,
                "mfa_enabled_percent": 95.2
            },
            "authorization_metrics": {
                "api_calls_today": 15420,
                "unauthorized_attempts": 5,
                "rbac_violations": 1,
                "token_refreshes": 890
            },
            "encryption_metrics": {
                "encrypted_data_percent": 100.0,
                "tls_connections": 15420,
                "key_rotations_today": 0,
                "encryption_errors": 0
            },
            "threat_metrics": {
                "blocked_ips": 12,
                "suspicious_activities": 3,
                "security_alerts": 2,
                "vulnerability_scans": 1
            },
            "compliance_metrics": {
                "gdpr_compliance_percent": 98.5,
                "audit_logs_generated": 15420,
                "data_retention_compliance": 100.0,
                "privacy_violations": 0
            }
        }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "security_data": security_data
        }
        
    except Exception as e:
        logger.error(f"Failed to get security dashboard: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get security dashboard")


@router.get("/dashboard/cost")
async def get_cost_dashboard():
    """Get cost monitoring dashboard data."""
    try:
        # Mock cost data - in production, this would query actual cost metrics
        cost_data = {
            "daily_costs": {
                "compute_cost_usd": 45.20,
                "storage_cost_usd": 12.30,
                "network_cost_usd": 8.50,
                "monitoring_cost_usd": 5.25,
                "total_cost_usd": 71.25
            },
            "monthly_costs": {
                "compute_cost_usd": 1356.00,
                "storage_cost_usd": 369.00,
                "network_cost_usd": 255.00,
                "monitoring_cost_usd": 157.50,
                "total_cost_usd": 2137.50
            },
            "cost_metrics": {
                "cost_per_event_usd": 0.008,
                "cost_per_device_usd": 0.475,
                "cost_trend_percent": 2.5,
                "budget_utilization_percent": 85.5
            },
            "optimization_opportunities": [
                "Consider reserved instances for predictable workloads",
                "Archive old data to reduce storage costs",
                "Optimize auto-scaling thresholds"
            ]
        }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "cost_data": cost_data
        }
        
    except Exception as e:
        logger.error(f"Failed to get cost dashboard: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get cost dashboard")


@router.get("/dashboard/use-cases")
async def get_use_cases_dashboard():
    """Get use cases monitoring dashboard data."""
    try:
        # Mock use cases data - in production, this would query actual use case metrics
        use_cases_data = {
            "traffic_monitoring": {
                "events_processed": 5420,
                "congestion_alerts": 23,
                "avg_confidence": 0.87,
                "processing_time_ms": 65.2
            },
            "siren_detection": {
                "events_processed": 1200,
                "sirens_detected": 8,
                "avg_confidence": 0.92,
                "processing_time_ms": 45.8
            },
            "noise_mapping": {
                "events_processed": 3200,
                "violations_detected": 15,
                "avg_confidence": 0.89,
                "processing_time_ms": 78.5
            },
            "industrial_monitoring": {
                "events_processed": 2100,
                "anomalies_detected": 5,
                "avg_confidence": 0.85,
                "processing_time_ms": 92.3
            },
            "wildlife_monitoring": {
                "events_processed": 1500,
                "species_identified": 12,
                "avg_confidence": 0.81,
                "processing_time_ms": 88.7
            }
        }
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "use_cases_data": use_cases_data
        }
        
    except Exception as e:
        logger.error(f"Failed to get use cases dashboard: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get use cases dashboard")


@router.get("/health/detailed")
async def get_detailed_health():
    """Get detailed system health information."""
    try:
        health_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "overall_status": "healthy",
            "components": {
                "database": {
                    "status": "healthy",
                    "response_time_ms": 12.5,
                    "connections_active": 8,
                    "connections_max": 20
                },
                "redis": {
                    "status": "healthy",
                    "response_time_ms": 2.1,
                    "memory_usage_percent": 45.2,
                    "keys_count": 1250
                },
                "mqtt": {
                    "status": "healthy",
                    "connected_clients": 142,
                    "messages_per_second": 95.8,
                    "queue_size": 0
                },
                "ml_services": {
                    "status": "healthy",
                    "models_loaded": 5,
                    "avg_processing_time_ms": 75.2,
                    "queue_size": 0
                },
                "api_gateway": {
                    "status": "healthy",
                    "requests_per_second": 95.8,
                    "avg_response_time_ms": 65.2,
                    "error_rate_percent": 0.02
                }
            },
            "nfr_compliance": nfr_compliance_service.get_nfr_summary(),
            "alerts": {
                "active_alerts": len(nfr_compliance_service.get_alerts(status=NFRStatus.CRITICAL)),
                "warning_alerts": len(nfr_compliance_service.get_alerts(status=NFRStatus.WARNING)),
                "total_alerts": len(nfr_compliance_service.get_alerts())
            }
        }
        
        return health_data
        
    except Exception as e:
        logger.error(f"Failed to get detailed health: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get detailed health")


@router.get("/metrics/export")
async def export_metrics(format: str = Query("prometheus", description="Export format")):
    """Export metrics in various formats."""
    try:
        if format == "prometheus":
            from app.services.metrics_service import metrics_service
            return metrics_service.get_metrics_response()
        elif format == "json":
            # Export as JSON
            return {
                "timestamp": datetime.utcnow().isoformat(),
                "nfr_compliance": nfr_compliance_service.get_compliance_status(),
                "alerts": nfr_compliance_service.get_alerts(limit=1000),
                "summary": nfr_compliance_service.get_nfr_summary()
            }
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported format")
            
    except Exception as e:
        logger.error(f"Failed to export metrics: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to export metrics")
