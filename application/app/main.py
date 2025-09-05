"""Main FastAPI application."""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import logging
import os

from app.config import settings
from app.services.database import db_service
from app.services.mqtt_service import mqtt_service
from app.services.background_tasks import background_tasks
from app.api.routers import devices, telemetry, alerts, analytics, mqtt, auth, metrics, use_cases, monitoring

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    logger.info("Starting IoT Sound Detection POC Application")
    
    try:
        # Create database tables
        db_service.create_tables()
        logger.info("Database tables created/verified")
        
        # Create storage directories
        os.makedirs(settings.audio_storage_path, exist_ok=True)
        os.makedirs(settings.model_storage_path, exist_ok=True)
        logger.info("Storage directories created")
        
        # Connect to MQTT broker
        if mqtt_service.connect():
            logger.info("Connected to MQTT broker")
        else:
            logger.warning("Failed to connect to MQTT broker")
        
        # Start background tasks
        background_tasks.start()
        logger.info("Background tasks started")
        
    except Exception as e:
        logger.error(f"Error during startup: {e}")
        raise
    
    yield
    
    # Shutdown
    logger.info("Shutting down IoT Sound Detection POC Application")
    
    try:
        # Stop background tasks
        background_tasks.stop()
        logger.info("Background tasks stopped")
        
        # Disconnect from MQTT
        mqtt_service.disconnect()
        logger.info("Disconnected from MQTT broker")
        
    except Exception as e:
        logger.error(f"Error during shutdown: {e}")


# Create FastAPI application
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="IoT Sound Detection and Drone Detection POC Application",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add trusted host middleware
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]  # Configure appropriately for production
)

# Include API routers
app.include_router(devices.router)
app.include_router(telemetry.router)
app.include_router(alerts.router)
app.include_router(analytics.router)
app.include_router(mqtt.router)
app.include_router(auth.router)
app.include_router(metrics.router)
app.include_router(use_cases.router)
app.include_router(monitoring.router)


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "IoT Sound Detection POC API",
        "version": settings.app_version,
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    try:
        # Check database connection
        session = db_service.get_session()
        try:
            # Simple query to test database
            session.execute("SELECT 1")
            db_status = "healthy"
        except Exception:
            db_status = "unhealthy"
        finally:
            db_service.close_session(session)
        
        # Check MQTT connection
        mqtt_status = "connected" if mqtt_service.is_connected() else "disconnected"
        
        # Check background tasks
        tasks_status = "running" if background_tasks.running else "stopped"
        
        overall_status = "healthy" if all(status in ["healthy", "connected", "running"] 
                                        for status in [db_status, mqtt_status, tasks_status]) else "degraded"
        
        return {
            "status": overall_status,
            "database": db_status,
            "mqtt": mqtt_status,
            "background_tasks": tasks_status,
            "version": settings.app_version
        }
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
            "version": settings.app_version
        }


@app.get("/metrics")
async def get_metrics():
    """Get application metrics."""
    try:
        # This would integrate with Prometheus metrics in a real implementation
        return {
            "message": "Metrics endpoint - integrate with Prometheus for production",
            "note": "This is a POC implementation"
        }
    except Exception as e:
        logger.error(f"Failed to get metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get metrics")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.debug
    )
