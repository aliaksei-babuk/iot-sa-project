"""Alert management API endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional, List

from app.services.alert_service import AlertService
from app.schemas.alert import (
    AlertCreate, AlertUpdate, AlertResponse, AlertListResponse,
    AlertType, AlertSeverity, AlertStatus
)
from app.api.dependencies import get_alert_service

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.post("/", response_model=AlertResponse, status_code=status.HTTP_201_CREATED)
async def create_alert(
    alert_data: AlertCreate,
    alert_service: AlertService = Depends(get_alert_service)
):
    """Create a new alert."""
    try:
        alert = alert_service.create_alert(alert_data)
        return alert
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to create alert")


@router.get("/", response_model=AlertListResponse)
async def list_alerts(
    device_id: Optional[str] = Query(None, description="Filter by device ID"),
    alert_type: Optional[AlertType] = Query(None, description="Filter by alert type"),
    severity: Optional[AlertSeverity] = Query(None, description="Filter by severity"),
    status: Optional[AlertStatus] = Query(None, description="Filter by status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=200, description="Page size"),
    alert_service: AlertService = Depends(get_alert_service)
):
    """List alerts with filtering and pagination."""
    try:
        result = alert_service.list_alerts(
            device_id=device_id,
            alert_type=alert_type,
            severity=severity,
            status=status,
            page=page,
            page_size=page_size
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to list alerts")


@router.get("/active", response_model=List[AlertResponse])
async def get_active_alerts(
    device_id: Optional[str] = Query(None, description="Filter by device ID"),
    alert_service: AlertService = Depends(get_alert_service)
):
    """Get active alerts."""
    try:
        alerts = alert_service.get_active_alerts(device_id=device_id)
        return alerts
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get active alerts")


@router.get("/critical", response_model=List[AlertResponse])
async def get_critical_alerts(
    alert_service: AlertService = Depends(get_alert_service)
):
    """Get critical alerts."""
    try:
        alerts = alert_service.get_critical_alerts()
        return alerts
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get critical alerts")


@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(
    alert_id: str,
    alert_service: AlertService = Depends(get_alert_service)
):
    """Get alert by ID."""
    alert = alert_service.get_alert(alert_id)
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    return alert


@router.put("/{alert_id}", response_model=AlertResponse)
async def update_alert(
    alert_id: str,
    alert_data: AlertUpdate,
    alert_service: AlertService = Depends(get_alert_service)
):
    """Update alert status."""
    alert = alert_service.update_alert(alert_id, alert_data)
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    return alert


@router.patch("/{alert_id}/acknowledge", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: str,
    alert_service: AlertService = Depends(get_alert_service)
):
    """Acknowledge an alert."""
    success = alert_service.acknowledge_alert(alert_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found or already acknowledged")
    
    # Return updated alert
    alert = alert_service.get_alert(alert_id)
    return alert


@router.patch("/{alert_id}/resolve", response_model=AlertResponse)
async def resolve_alert(
    alert_id: str,
    alert_service: AlertService = Depends(get_alert_service)
):
    """Resolve an alert."""
    success = alert_service.resolve_alert(alert_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found or already resolved")
    
    # Return updated alert
    alert = alert_service.get_alert(alert_id)
    return alert


@router.get("/{device_id}/summary")
async def get_device_alert_summary(
    device_id: str,
    alert_service: AlertService = Depends(get_alert_service)
):
    """Get alert summary for a device."""
    try:
        # Get all alerts for device
        all_alerts = alert_service.list_alerts(device_id=device_id, page_size=1000)
        
        # Calculate summary statistics
        total_alerts = all_alerts.total
        active_alerts = sum(1 for alert in all_alerts.alerts if alert.status == AlertStatus.ACTIVE)
        acknowledged_alerts = sum(1 for alert in all_alerts.alerts if alert.status == AlertStatus.ACKNOWLEDGED)
        resolved_alerts = sum(1 for alert in all_alerts.alerts if alert.status == AlertStatus.RESOLVED)
        
        # Count by severity
        critical_count = sum(1 for alert in all_alerts.alerts if alert.severity == AlertSeverity.CRITICAL)
        high_count = sum(1 for alert in all_alerts.alerts if alert.severity == AlertSeverity.HIGH)
        medium_count = sum(1 for alert in all_alerts.alerts if alert.severity == AlertSeverity.MEDIUM)
        low_count = sum(1 for alert in all_alerts.alerts if alert.severity == AlertSeverity.LOW)
        
        # Count by type
        drone_detected_count = sum(1 for alert in all_alerts.alerts if alert.alert_type == AlertType.DRONE_DETECTED)
        anomaly_count = sum(1 for alert in all_alerts.alerts if alert.alert_type == AlertType.ANOMALY)
        system_error_count = sum(1 for alert in all_alerts.alerts if alert.alert_type == AlertType.SYSTEM_ERROR)
        device_offline_count = sum(1 for alert in all_alerts.alerts if alert.alert_type == AlertType.DEVICE_OFFLINE)
        
        return {
            "device_id": device_id,
            "total_alerts": total_alerts,
            "active_alerts": active_alerts,
            "acknowledged_alerts": acknowledged_alerts,
            "resolved_alerts": resolved_alerts,
            "severity_breakdown": {
                "critical": critical_count,
                "high": high_count,
                "medium": medium_count,
                "low": low_count
            },
            "type_breakdown": {
                "drone_detected": drone_detected_count,
                "anomaly": anomaly_count,
                "system_error": system_error_count,
                "device_offline": device_offline_count
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to get alert summary")
