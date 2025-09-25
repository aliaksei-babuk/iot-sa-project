"""
Swarm Management Service - Сервис управления роем IoT агентов
"""

import asyncio
import json
import logging
import subprocess
import time
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_, desc

from ..models.database import Device, TelemetryData, Alert
from ..schemas.swarm import (
    SwarmAgentCreate, SwarmAgentUpdate, SwarmAgentResponse,
    SwarmStatus, SwarmHealthMetrics, SwarmConfiguration,
    SwarmDeploymentRequest, SwarmDeploymentResponse,
    SwarmAgentStatus, SwarmHealthStatus, SwarmDeploymentStatus
)

logger = logging.getLogger(__name__)

class SwarmService:
    """Сервис управления роем IoT агентов"""
    
    def __init__(self):
        self.swarm_id = "sound-analytics-swarm"
        self.agent_version = "2.0.0"
        self.deployment_timeout = 300  # 5 minutes
    
    async def get_swarm_status(self, db: Session) -> SwarmStatus:
        """Получить статус роя агентов"""
        try:
            # Подсчет агентов по статусам
            total_agents = db.query(Device).filter(
                Device.tags.contains({"swarmType": "sound-agent"})
            ).count()
            
            active_agents = db.query(Device).filter(
                and_(
                    Device.tags.contains({"swarmType": "sound-agent"}),
                    Device.status == "active"
                )
            ).count()
            
            inactive_agents = db.query(Device).filter(
                and_(
                    Device.tags.contains({"swarmType": "sound-agent"}),
                    Device.status == "inactive"
                )
            ).count()
            
            error_agents = db.query(Device).filter(
                and_(
                    Device.tags.contains({"swarmType": "sound-agent"}),
                    Device.status == "error"
                )
            ).count()
            
            offline_agents = db.query(Device).filter(
                and_(
                    Device.tags.contains({"swarmType": "sound-agent"}),
                    or_(
                        Device.last_seen < datetime.utcnow() - timedelta(minutes=5),
                        Device.status == "offline"
                    )
                )
            ).count()
            
            # Расчет показателя здоровья
            health_score = self._calculate_health_score(active_agents, total_agents, error_agents)
            
            return SwarmStatus(
                swarm_id=self.swarm_id,
                total_agents=total_agents,
                active_agents=active_agents,
                inactive_agents=inactive_agents,
                error_agents=error_agents,
                offline_agents=offline_agents,
                last_updated=datetime.utcnow(),
                health_score=health_score
            )
        except Exception as e:
            logger.error(f"Failed to get swarm status: {e}")
            raise
    
    async def list_agents(
        self, 
        db: Session, 
        status: Optional[str] = None,
        location: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[SwarmAgentResponse]:
        """Получить список агентов роя"""
        try:
            query = db.query(Device).filter(
                Device.tags.contains({"swarmType": "sound-agent"})
            )
            
            if status:
                query = query.filter(Device.status == status)
            
            if location:
                query = query.filter(Device.tags.contains({"location": location}))
            
            devices = query.offset(offset).limit(limit).all()
            
            agents = []
            for device in devices:
                agent = await self._device_to_agent_response(device)
                agents.append(agent)
            
            return agents
        except Exception as e:
            logger.error(f"Failed to list agents: {e}")
            raise
    
    async def create_agent(self, db: Session, agent_data: SwarmAgentCreate) -> SwarmAgentResponse:
        """Создать нового агента роя"""
        try:
            # Создать устройство в базе данных
            device = Device(
                device_id=agent_data.agent_id,
                name=f"Swarm Agent {agent_data.agent_id}",
                device_type="sound-agent",
                status="inactive",
                tags={
                    "swarmType": agent_data.agent_type.value,
                    "swarmId": agent_data.swarm_id,
                    "location": agent_data.location,
                    "agentVersion": agent_data.version,
                    "status": "inactive"
                },
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            
            db.add(device)
            db.commit()
            db.refresh(device)
            
            # Создать конфигурацию агента
            configuration = {
                "audioSettings": {
                    "sampleRate": 22050,
                    "duration": 2.0,
                    "channels": 1,
                    "format": "wav"
                },
                "mlSettings": {
                    "modelVersion": "2.0.0",
                    "confidenceThreshold": 0.7,
                    "enableRealTimeProcessing": True
                },
                "networkSettings": {
                    "retryAttempts": 3,
                    "timeoutSeconds": 30,
                    "enableCompression": True
                }
            }
            
            # Обновить конфигурацию если предоставлена
            if agent_data.deployment_config:
                configuration.update(agent_data.deployment_config)
            
            device.tags["configuration"] = json.dumps(configuration)
            db.commit()
            
            return await self._device_to_agent_response(device)
        except Exception as e:
            logger.error(f"Failed to create agent: {e}")
            db.rollback()
            raise
    
    async def get_agent(self, db: Session, agent_id: str) -> Optional[SwarmAgentResponse]:
        """Получить информацию об агенте"""
        try:
            device = db.query(Device).filter(
                and_(
                    Device.device_id == agent_id,
                    Device.tags.contains({"swarmType": "sound-agent"})
                )
            ).first()
            
            if not device:
                return None
            
            return await self._device_to_agent_response(device)
        except Exception as e:
            logger.error(f"Failed to get agent: {e}")
            raise
    
    async def update_agent(
        self, 
        db: Session, 
        agent_id: str, 
        agent_data: SwarmAgentUpdate
    ) -> Optional[SwarmAgentResponse]:
        """Обновить конфигурацию агента"""
        try:
            device = db.query(Device).filter(
                and_(
                    Device.device_id == agent_id,
                    Device.tags.contains({"swarmType": "sound-agent"})
                )
            ).first()
            
            if not device:
                return None
            
            # Обновить поля
            if agent_data.location:
                device.tags["location"] = agent_data.location
            
            if agent_data.description:
                device.tags["description"] = agent_data.description
            
            if agent_data.tags:
                device.tags.update(agent_data.tags)
            
            if agent_data.status:
                device.status = agent_data.status.value
                device.tags["status"] = agent_data.status.value
            
            if agent_data.configuration:
                device.tags["configuration"] = json.dumps(agent_data.configuration)
            
            device.updated_at = datetime.utcnow()
            db.commit()
            
            return await self._device_to_agent_response(device)
        except Exception as e:
            logger.error(f"Failed to update agent: {e}")
            db.rollback()
            raise
    
    async def delete_agent(self, db: Session, agent_id: str) -> bool:
        """Удалить агента из роя"""
        try:
            device = db.query(Device).filter(
                and_(
                    Device.device_id == agent_id,
                    Device.tags.contains({"swarmType": "sound-agent"})
                )
            ).first()
            
            if not device:
                return False
            
            # Удалить связанные данные
            db.query(TelemetryData).filter(TelemetryData.device_id == device.id).delete()
            db.query(Alert).filter(Alert.device_id == device.id).delete()
            
            # Удалить устройство
            db.delete(device)
            db.commit()
            
            return True
        except Exception as e:
            logger.error(f"Failed to delete agent: {e}")
            db.rollback()
            raise
    
    async def deploy_agent(
        self, 
        db: Session, 
        agent_id: str, 
        deployment_request: SwarmDeploymentRequest
    ) -> SwarmDeploymentResponse:
        """Развернуть агента на устройстве"""
        try:
            deployment_id = f"deploy-{agent_id}-{int(time.time())}"
            
            # Обновить статус агента
            device = db.query(Device).filter(Device.device_id == agent_id).first()
            if device:
                device.status = "deploying"
                device.tags["deploymentStatus"] = "in_progress"
                device.tags["deploymentId"] = deployment_id
                device.updated_at = datetime.utcnow()
                db.commit()
            
            # Запустить развертывание в фоне
            asyncio.create_task(
                self._deploy_agent_async(agent_id, deployment_request, deployment_id)
            )
            
            return SwarmDeploymentResponse(
                agent_id=agent_id,
                deployment_id=deployment_id,
                status=SwarmDeploymentStatus.IN_PROGRESS,
                message="Deployment started",
                started_at=datetime.utcnow(),
                estimated_completion=datetime.utcnow() + timedelta(minutes=5)
            )
        except Exception as e:
            logger.error(f"Failed to deploy agent: {e}")
            raise
    
    async def start_agent(self, db: Session, agent_id: str) -> bool:
        """Запустить агента"""
        try:
            device = db.query(Device).filter(Device.device_id == agent_id).first()
            if not device:
                return False
            
            device.status = "active"
            device.tags["status"] = "active"
            device.updated_at = datetime.utcnow()
            db.commit()
            
            # Отправить команду запуска (в реальной реализации)
            await self._send_agent_command(agent_id, "start")
            
            return True
        except Exception as e:
            logger.error(f"Failed to start agent: {e}")
            db.rollback()
            raise
    
    async def stop_agent(self, db: Session, agent_id: str) -> bool:
        """Остановить агента"""
        try:
            device = db.query(Device).filter(Device.device_id == agent_id).first()
            if not device:
                return False
            
            device.status = "inactive"
            device.tags["status"] = "inactive"
            device.updated_at = datetime.utcnow()
            db.commit()
            
            # Отправить команду остановки (в реальной реализации)
            await self._send_agent_command(agent_id, "stop")
            
            return True
        except Exception as e:
            logger.error(f"Failed to stop agent: {e}")
            db.rollback()
            raise
    
    async def get_agent_health(
        self, 
        db: Session, 
        agent_id: str, 
        hours: int = 24
    ) -> Optional[SwarmHealthMetrics]:
        """Получить метрики здоровья агента"""
        try:
            # Получить последние данные телеметрии агента
            since_time = datetime.utcnow() - timedelta(hours=hours)
            
            telemetry = db.query(TelemetryData).filter(
                and_(
                    TelemetryData.device_id == agent_id,
                    TelemetryData.timestamp >= since_time,
                    TelemetryData.data_type == "health"
                )
            ).order_by(desc(TelemetryData.timestamp)).first()
            
            if not telemetry:
                return None
            
            # Извлечь метрики из данных телеметрии
            payload = telemetry.payload if isinstance(telemetry.payload, dict) else json.loads(telemetry.payload)
            
            return SwarmHealthMetrics(
                agent_id=agent_id,
                timestamp=telemetry.timestamp,
                cpu_usage=payload.get("cpu_usage", 0.0),
                memory_usage=payload.get("memory_usage", 0.0),
                disk_usage=payload.get("disk_usage", 0.0),
                network_latency=payload.get("network_latency"),
                audio_quality=payload.get("audio_quality"),
                ml_processing_time=payload.get("ml_processing_time"),
                status=SwarmHealthStatus(payload.get("status", "unknown")),
                alerts=payload.get("alerts", [])
            )
        except Exception as e:
            logger.error(f"Failed to get agent health: {e}")
            raise
    
    async def get_agent_telemetry(
        self, 
        db: Session, 
        agent_id: str, 
        hours: int = 24,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Получить телеметрию агента"""
        try:
            since_time = datetime.utcnow() - timedelta(hours=hours)
            
            telemetry_data = db.query(TelemetryData).filter(
                and_(
                    TelemetryData.device_id == agent_id,
                    TelemetryData.timestamp >= since_time
                )
            ).order_by(desc(TelemetryData.timestamp)).limit(limit).all()
            
            return [
                {
                    "id": td.id,
                    "timestamp": td.timestamp,
                    "data_type": td.data_type,
                    "payload": td.payload,
                    "location": td.location,
                    "quality_score": td.quality_score
                }
                for td in telemetry_data
            ]
        except Exception as e:
            logger.error(f"Failed to get agent telemetry: {e}")
            raise
    
    async def get_swarm_configuration(self, db: Session) -> SwarmConfiguration:
        """Получить конфигурацию роя"""
        try:
            # В реальной реализации конфигурация может храниться в отдельной таблице
            # Здесь возвращаем базовую конфигурацию
            return SwarmConfiguration(
                swarm_id=self.swarm_id,
                version=self.agent_version,
                audio_settings={
                    "sampleRate": 22050,
                    "duration": 2.0,
                    "channels": 1,
                    "format": "wav"
                },
                ml_settings={
                    "modelVersion": "2.0.0",
                    "confidenceThreshold": 0.7,
                    "enableRealTimeProcessing": True
                },
                network_settings={
                    "retryAttempts": 3,
                    "timeoutSeconds": 30,
                    "enableCompression": True
                },
                monitoring_settings={
                    "healthCheckInterval": 60,
                    "telemetryInterval": 30,
                    "alertThresholds": {
                        "cpu": 80,
                        "memory": 85,
                        "disk": 90
                    }
                },
                security_settings={
                    "encryptionEnabled": True,
                    "authenticationRequired": True,
                    "tlsVersion": "1.2"
                },
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
        except Exception as e:
            logger.error(f"Failed to get swarm configuration: {e}")
            raise
    
    async def update_swarm_configuration(
        self, 
        db: Session, 
        config: SwarmConfiguration
    ) -> SwarmConfiguration:
        """Обновить конфигурацию роя"""
        try:
            # В реальной реализации сохраняем конфигурацию в базе данных
            # Здесь просто возвращаем обновленную конфигурацию
            config.updated_at = datetime.utcnow()
            return config
        except Exception as e:
            logger.error(f"Failed to update swarm configuration: {e}")
            raise
    
    # Вспомогательные методы
    async def _device_to_agent_response(self, device: Device) -> SwarmAgentResponse:
        """Преобразовать устройство в ответ агента"""
        try:
            # Извлечь конфигурацию из тегов
            configuration = {}
            if "configuration" in device.tags:
                configuration = json.loads(device.tags["configuration"])
            
            # Определить статус здоровья
            health_status = SwarmHealthStatus.UNKNOWN
            if device.last_seen and device.last_seen > datetime.utcnow() - timedelta(minutes=5):
                health_status = SwarmHealthStatus.HEALTHY
            elif device.status == "error":
                health_status = SwarmHealthStatus.CRITICAL
            elif device.status == "inactive":
                health_status = SwarmHealthStatus.WARNING
            
            return SwarmAgentResponse(
                id=device.id,
                agent_id=device.device_id,
                swarm_id=device.tags.get("swarmId", self.swarm_id),
                agent_type=device.tags.get("swarmType", "sound-agent"),
                location=device.tags.get("location", "unknown"),
                version=device.tags.get("agentVersion", self.agent_version),
                description=device.tags.get("description"),
                tags=device.tags,
                status=SwarmAgentStatus(device.status),
                created_at=device.created_at,
                updated_at=device.updated_at,
                last_seen=device.last_seen,
                health_status=health_status,
                configuration=configuration,
                deployment_status=device.tags.get("deploymentStatus"),
                error_message=device.tags.get("errorMessage")
            )
        except Exception as e:
            logger.error(f"Failed to convert device to agent response: {e}")
            raise
    
    def _calculate_health_score(
        self, 
        active_agents: int, 
        total_agents: int, 
        error_agents: int
    ) -> float:
        """Рассчитать показатель здоровья роя"""
        if total_agents == 0:
            return 0.0
        
        # Базовый показатель на основе активных агентов
        base_score = (active_agents / total_agents) * 100
        
        # Штраф за ошибки
        error_penalty = (error_agents / total_agents) * 20
        
        # Финальный показатель
        health_score = max(0, base_score - error_penalty)
        
        return round(health_score, 2)
    
    async def _deploy_agent_async(
        self, 
        agent_id: str, 
        deployment_request: SwarmDeploymentRequest,
        deployment_id: str
    ):
        """Асинхронное развертывание агента"""
        try:
            # Здесь должна быть реальная логика развертывания
            # Например, SSH подключение к устройству и выполнение скрипта
            
            logger.info(f"Starting deployment of agent {agent_id}")
            
            # Имитация процесса развертывания
            await asyncio.sleep(30)  # Имитация времени развертывания
            
            # Обновить статус в базе данных
            # В реальной реализации здесь должен быть доступ к сессии БД
            logger.info(f"Deployment of agent {agent_id} completed")
            
        except Exception as e:
            logger.error(f"Failed to deploy agent {agent_id}: {e}")
    
    async def _send_agent_command(self, agent_id: str, command: str):
        """Отправить команду агенту"""
        try:
            # В реальной реализации здесь должна быть отправка команды через IoT Hub
            logger.info(f"Sending command '{command}' to agent {agent_id}")
        except Exception as e:
            logger.error(f"Failed to send command to agent {agent_id}: {e}")
    
    # Методы для фоновых задач
    async def deploy_agent_async(self, agent_id: str, deployment_config: Dict[str, Any]):
        """Асинхронное развертывание агента (для фоновых задач)"""
        await self._deploy_agent_async(agent_id, deployment_config, f"deploy-{agent_id}")
    
    async def cleanup_agent_async(self, agent_id: str):
        """Асинхронная очистка агента (для фоновых задач)"""
        logger.info(f"Cleaning up agent {agent_id}")
    
    async def monitor_deployment_async(self, agent_id: str, device_ip: str):
        """Асинхронный мониторинг развертывания (для фоновых задач)"""
        logger.info(f"Monitoring deployment of agent {agent_id} on {device_ip}")
    
    async def monitor_restart_async(self, agent_id: str):
        """Асинхронный мониторинг перезапуска (для фоновых задач)"""
        logger.info(f"Monitoring restart of agent {agent_id}")
    
    async def update_all_agents_config_async(self):
        """Асинхронное обновление конфигурации всех агентов (для фоновых задач)"""
        logger.info("Updating configuration for all agents")
    
    async def monitor_bulk_deployment_async(self, results: List[Dict[str, Any]]):
        """Асинхронный мониторинг массового развертывания (для фоновых задач)"""
        logger.info(f"Monitoring bulk deployment with {len(results)} results")


