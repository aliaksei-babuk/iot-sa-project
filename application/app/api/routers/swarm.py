"""
Swarm Management API - Управление роем IoT агентов
"""

from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_

from ..dependencies import get_db, get_current_user
from ...models.database import Device, TelemetryData, Alert
from ...services.swarm_service import SwarmService
from ...schemas.swarm import (
    SwarmAgentCreate, SwarmAgentUpdate, SwarmAgentResponse,
    SwarmStatus, SwarmHealthMetrics, SwarmConfiguration,
    SwarmDeploymentRequest, SwarmDeploymentResponse
)

router = APIRouter(prefix="/swarm", tags=["swarm"])

# Swarm Service instance
swarm_service = SwarmService()

@router.get("/status", response_model=SwarmStatus)
async def get_swarm_status(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить статус роя агентов"""
    try:
        status = await swarm_service.get_swarm_status(db)
        return status
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get swarm status: {str(e)}")

@router.get("/agents", response_model=List[SwarmAgentResponse])
async def list_swarm_agents(
    status: Optional[str] = None,
    location: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить список агентов роя"""
    try:
        agents = await swarm_service.list_agents(
            db, status=status, location=location, 
            limit=limit, offset=offset
        )
        return agents
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list agents: {str(e)}")

@router.post("/agents", response_model=SwarmAgentResponse)
async def create_swarm_agent(
    agent_data: SwarmAgentCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Создать нового агента роя"""
    try:
        agent = await swarm_service.create_agent(db, agent_data)
        
        # Запустить развертывание в фоне
        background_tasks.add_task(
            swarm_service.deploy_agent_async, 
            agent.id, agent_data.deployment_config
        )
        
        return agent
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to create agent: {str(e)}")

@router.get("/agents/{agent_id}", response_model=SwarmAgentResponse)
async def get_swarm_agent(
    agent_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить информацию об агенте"""
    try:
        agent = await swarm_service.get_agent(db, agent_id)
        if not agent:
            raise HTTPException(status_code=404, detail="Agent not found")
        return agent
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get agent: {str(e)}")

@router.put("/agents/{agent_id}", response_model=SwarmAgentResponse)
async def update_swarm_agent(
    agent_id: str,
    agent_data: SwarmAgentUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновить конфигурацию агента"""
    try:
        agent = await swarm_service.update_agent(db, agent_id, agent_data)
        if not agent:
            raise HTTPException(status_code=404, detail="Agent not found")
        return agent
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update agent: {str(e)}")

@router.delete("/agents/{agent_id}")
async def delete_swarm_agent(
    agent_id: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Удалить агента из роя"""
    try:
        success = await swarm_service.delete_agent(db, agent_id)
        if not success:
            raise HTTPException(status_code=404, detail="Agent not found")
        
        # Запустить очистку в фоне
        background_tasks.add_task(swarm_service.cleanup_agent_async, agent_id)
        
        return {"message": "Agent deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete agent: {str(e)}")

@router.post("/agents/{agent_id}/deploy", response_model=SwarmDeploymentResponse)
async def deploy_swarm_agent(
    agent_id: str,
    deployment_request: SwarmDeploymentRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Развернуть агента на устройстве"""
    try:
        result = await swarm_service.deploy_agent(
            db, agent_id, deployment_request
        )
        
        # Запустить мониторинг развертывания в фоне
        background_tasks.add_task(
            swarm_service.monitor_deployment_async, 
            agent_id, deployment_request.device_ip
        )
        
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to deploy agent: {str(e)}")

@router.post("/agents/{agent_id}/start")
async def start_swarm_agent(
    agent_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Запустить агента"""
    try:
        success = await swarm_service.start_agent(db, agent_id)
        if not success:
            raise HTTPException(status_code=404, detail="Agent not found")
        return {"message": "Agent started successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start agent: {str(e)}")

@router.post("/agents/{agent_id}/stop")
async def stop_swarm_agent(
    agent_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Остановить агента"""
    try:
        success = await swarm_service.stop_agent(db, agent_id)
        if not success:
            raise HTTPException(status_code=404, detail="Agent not found")
        return {"message": "Agent stopped successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to stop agent: {str(e)}")

@router.get("/agents/{agent_id}/health", response_model=SwarmHealthMetrics)
async def get_agent_health(
    agent_id: str,
    hours: int = 24,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить метрики здоровья агента"""
    try:
        health = await swarm_service.get_agent_health(db, agent_id, hours)
        if not health:
            raise HTTPException(status_code=404, detail="Agent not found")
        return health
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get agent health: {str(e)}")

@router.get("/agents/{agent_id}/telemetry")
async def get_agent_telemetry(
    agent_id: str,
    hours: int = 24,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить телеметрию агента"""
    try:
        telemetry = await swarm_service.get_agent_telemetry(
            db, agent_id, hours, limit
        )
        return telemetry
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get agent telemetry: {str(e)}")

@router.get("/configuration", response_model=SwarmConfiguration)
async def get_swarm_configuration(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить конфигурацию роя"""
    try:
        config = await swarm_service.get_swarm_configuration(db)
        return config
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get swarm configuration: {str(e)}")

@router.put("/configuration", response_model=SwarmConfiguration)
async def update_swarm_configuration(
    config: SwarmConfiguration,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Обновить конфигурацию роя"""
    try:
        updated_config = await swarm_service.update_swarm_configuration(db, config)
        
        # Запустить обновление конфигурации всех агентов в фоне
        background_tasks.add_task(swarm_service.update_all_agents_config_async)
        
        return updated_config
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to update swarm configuration: {str(e)}")

@router.get("/analytics/sound-classification")
async def get_sound_classification_analytics(
    hours: int = 24,
    group_by: str = "hour",
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить аналитику классификации звуков"""
    try:
        analytics = await swarm_service.get_sound_classification_analytics(
            db, hours, group_by
        )
        return analytics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get sound classification analytics: {str(e)}")

@router.get("/analytics/agent-performance")
async def get_agent_performance_analytics(
    hours: int = 24,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить аналитику производительности агентов"""
    try:
        analytics = await swarm_service.get_agent_performance_analytics(db, hours)
        return analytics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get agent performance analytics: {str(e)}")

@router.get("/alerts")
async def get_swarm_alerts(
    severity: Optional[str] = None,
    status: Optional[str] = None,
    hours: int = 24,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить алерты роя"""
    try:
        alerts = await swarm_service.get_swarm_alerts(
            db, severity, status, hours, limit
        )
        return alerts
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get swarm alerts: {str(e)}")

@router.post("/agents/{agent_id}/restart")
async def restart_swarm_agent(
    agent_id: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Перезапустить агента"""
    try:
        success = await swarm_service.restart_agent(db, agent_id)
        if not success:
            raise HTTPException(status_code=404, detail="Agent not found")
        
        # Запустить мониторинг перезапуска в фоне
        background_tasks.add_task(swarm_service.monitor_restart_async, agent_id)
        
        return {"message": "Agent restart initiated"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to restart agent: {str(e)}")

@router.get("/agents/{agent_id}/logs")
async def get_agent_logs(
    agent_id: str,
    hours: int = 24,
    level: Optional[str] = None,
    limit: int = 1000,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить логи агента"""
    try:
        logs = await swarm_service.get_agent_logs(
            db, agent_id, hours, level, limit
        )
        return logs
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get agent logs: {str(e)}")

@router.post("/agents/bulk-deploy")
async def bulk_deploy_agents(
    deployment_requests: List[SwarmDeploymentRequest],
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Массовое развертывание агентов"""
    try:
        results = await swarm_service.bulk_deploy_agents(db, deployment_requests)
        
        # Запустить мониторинг массового развертывания в фоне
        background_tasks.add_task(swarm_service.monitor_bulk_deployment_async, results)
        
        return {"message": f"Bulk deployment initiated for {len(deployment_requests)} agents", "results": results}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to bulk deploy agents: {str(e)}")

@router.get("/metrics/summary")
async def get_swarm_metrics_summary(
    hours: int = 24,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Получить сводку метрик роя"""
    try:
        metrics = await swarm_service.get_swarm_metrics_summary(db, hours)
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get swarm metrics summary: {str(e)}")


