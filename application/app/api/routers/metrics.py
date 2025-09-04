"""Metrics API endpoints."""
from fastapi import APIRouter, Depends
from fastapi.responses import Response
import time

from app.services.metrics_service import metrics_service

router = APIRouter(prefix="/metrics", tags=["metrics"])


@router.get("/")
async def get_metrics():
    """Get Prometheus metrics."""
    return metrics_service.get_metrics_response()


@router.get("/health")
async def get_metrics_health():
    """Get metrics service health."""
    try:
        # Test metrics generation
        metrics = metrics_service.get_metrics()
        return {
            "status": "healthy",
            "metrics_available": len(metrics) > 0,
            "timestamp": time.time()
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": time.time()
        }
