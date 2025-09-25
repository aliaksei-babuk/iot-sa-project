"""
Swarm Management Schemas - Схемы данных для управления роем агентов
"""

from typing import List, Optional, Dict, Any, Union
from datetime import datetime
from pydantic import BaseModel, Field, validator
from enum import Enum

class SwarmAgentStatus(str, Enum):
    """Статус агента роя"""
    INACTIVE = "inactive"
    ACTIVE = "active"
    DEPLOYING = "deploying"
    ERROR = "error"
    MAINTENANCE = "maintenance"
    OFFLINE = "offline"

class SwarmAgentType(str, Enum):
    """Тип агента роя"""
    SOUND_AGENT = "sound-agent"
    ML_AGENT = "ml-agent"
    MONITORING_AGENT = "monitoring-agent"
    GATEWAY_AGENT = "gateway-agent"

class SwarmDeploymentStatus(str, Enum):
    """Статус развертывания"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"

class SwarmHealthStatus(str, Enum):
    """Статус здоровья агента"""
    HEALTHY = "healthy"
    WARNING = "warning"
    CRITICAL = "critical"
    UNKNOWN = "unknown"

# Base Models
class SwarmAgentBase(BaseModel):
    """Базовая модель агента роя"""
    agent_id: str = Field(..., description="Уникальный идентификатор агента")
    swarm_id: str = Field(..., description="Идентификатор роя")
    agent_type: SwarmAgentType = Field(..., description="Тип агента")
    location: str = Field(..., description="Местоположение агента")
    version: str = Field(..., description="Версия агента")
    description: Optional[str] = Field(None, description="Описание агента")
    tags: Optional[Dict[str, str]] = Field(default_factory=dict, description="Теги агента")

class SwarmAgentCreate(SwarmAgentBase):
    """Создание агента роя"""
    deployment_config: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Конфигурация развертывания")
    device_ip: Optional[str] = Field(None, description="IP адрес устройства")
    ssh_user: Optional[str] = Field(None, description="SSH пользователь для развертывания")
    ssh_key: Optional[str] = Field(None, description="SSH ключ для развертывания")

class SwarmAgentUpdate(BaseModel):
    """Обновление агента роя"""
    location: Optional[str] = Field(None, description="Местоположение агента")
    description: Optional[str] = Field(None, description="Описание агента")
    tags: Optional[Dict[str, str]] = Field(None, description="Теги агента")
    status: Optional[SwarmAgentStatus] = Field(None, description="Статус агента")
    configuration: Optional[Dict[str, Any]] = Field(None, description="Конфигурация агента")

class SwarmAgentResponse(SwarmAgentBase):
    """Ответ с информацией об агенте"""
    id: int = Field(..., description="Внутренний ID агента")
    status: SwarmAgentStatus = Field(..., description="Статус агента")
    created_at: datetime = Field(..., description="Время создания")
    updated_at: datetime = Field(..., description="Время последнего обновления")
    last_seen: Optional[datetime] = Field(None, description="Время последнего контакта")
    health_status: SwarmHealthStatus = Field(..., description="Статус здоровья")
    configuration: Dict[str, Any] = Field(default_factory=dict, description="Конфигурация агента")
    deployment_status: Optional[SwarmDeploymentStatus] = Field(None, description="Статус развертывания")
    error_message: Optional[str] = Field(None, description="Сообщение об ошибке")

    class Config:
        from_attributes = True

# Swarm Status Models
class SwarmStatus(BaseModel):
    """Статус роя агентов"""
    swarm_id: str = Field(..., description="Идентификатор роя")
    total_agents: int = Field(..., description="Общее количество агентов")
    active_agents: int = Field(..., description="Количество активных агентов")
    inactive_agents: int = Field(..., description="Количество неактивных агентов")
    error_agents: int = Field(..., description="Количество агентов с ошибками")
    offline_agents: int = Field(..., description="Количество офлайн агентов")
    last_updated: datetime = Field(..., description="Время последнего обновления")
    health_score: float = Field(..., description="Общий показатель здоровья роя (0-100)")

# Health Metrics Models
class SwarmHealthMetrics(BaseModel):
    """Метрики здоровья агента"""
    agent_id: str = Field(..., description="Идентификатор агента")
    timestamp: datetime = Field(..., description="Время измерения")
    cpu_usage: float = Field(..., description="Использование CPU (%)")
    memory_usage: float = Field(..., description="Использование памяти (%)")
    disk_usage: float = Field(..., description="Использование диска (%)")
    network_latency: Optional[float] = Field(None, description="Задержка сети (мс)")
    audio_quality: Optional[float] = Field(None, description="Качество аудио (0-1)")
    ml_processing_time: Optional[float] = Field(None, description="Время обработки ML (мс)")
    status: SwarmHealthStatus = Field(..., description="Статус здоровья")
    alerts: List[str] = Field(default_factory=list, description="Список предупреждений")

# Configuration Models
class SwarmConfiguration(BaseModel):
    """Конфигурация роя"""
    swarm_id: str = Field(..., description="Идентификатор роя")
    version: str = Field(..., description="Версия конфигурации")
    audio_settings: Dict[str, Any] = Field(..., description="Настройки аудио")
    ml_settings: Dict[str, Any] = Field(..., description="Настройки ML")
    network_settings: Dict[str, Any] = Field(..., description="Настройки сети")
    monitoring_settings: Dict[str, Any] = Field(..., description="Настройки мониторинга")
    security_settings: Dict[str, Any] = Field(..., description="Настройки безопасности")
    created_at: datetime = Field(..., description="Время создания")
    updated_at: datetime = Field(..., description="Время последнего обновления")

# Deployment Models
class SwarmDeploymentRequest(BaseModel):
    """Запрос на развертывание агента"""
    agent_id: str = Field(..., description="Идентификатор агента")
    device_ip: str = Field(..., description="IP адрес устройства")
    ssh_user: str = Field(..., description="SSH пользователь")
    ssh_key: Optional[str] = Field(None, description="SSH ключ")
    ssh_password: Optional[str] = Field(None, description="SSH пароль")
    deployment_config: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Конфигурация развертывания")
    force_redeploy: bool = Field(False, description="Принудительное переразвертывание")

class SwarmDeploymentResponse(BaseModel):
    """Ответ на развертывание агента"""
    agent_id: str = Field(..., description="Идентификатор агента")
    deployment_id: str = Field(..., description="Идентификатор развертывания")
    status: SwarmDeploymentStatus = Field(..., description="Статус развертывания")
    message: str = Field(..., description="Сообщение о статусе")
    started_at: datetime = Field(..., description="Время начала развертывания")
    estimated_completion: Optional[datetime] = Field(None, description="Ожидаемое время завершения")

# Telemetry Models
class SwarmTelemetryData(BaseModel):
    """Данные телеметрии агента"""
    agent_id: str = Field(..., description="Идентификатор агента")
    swarm_id: str = Field(..., description="Идентификатор роя")
    timestamp: datetime = Field(..., description="Время измерения")
    data_type: str = Field(..., description="Тип данных")
    payload: Dict[str, Any] = Field(..., description="Полезная нагрузка")
    location: Optional[str] = Field(None, description="Местоположение")
    quality_score: Optional[float] = Field(None, description="Показатель качества данных")

# Analytics Models
class SoundClassificationAnalytics(BaseModel):
    """Аналитика классификации звуков"""
    time_period: str = Field(..., description="Временной период")
    total_classifications: int = Field(..., description="Общее количество классификаций")
    classifications_by_type: Dict[str, int] = Field(..., description="Классификации по типам")
    average_confidence: float = Field(..., description="Средняя уверенность")
    drone_detections: int = Field(..., description="Количество обнаружений дронов")
    top_agents: List[Dict[str, Any]] = Field(..., description="Топ агенты по активности")

class AgentPerformanceAnalytics(BaseModel):
    """Аналитика производительности агентов"""
    time_period: str = Field(..., description="Временной период")
    total_agents: int = Field(..., description="Общее количество агентов")
    average_uptime: float = Field(..., description="Среднее время работы (%)")
    average_cpu_usage: float = Field(..., description="Среднее использование CPU (%)")
    average_memory_usage: float = Field(..., description="Среднее использование памяти (%)")
    error_rate: float = Field(..., description="Частота ошибок (%)")
    top_performers: List[Dict[str, Any]] = Field(..., description="Топ производители")

# Alert Models
class SwarmAlert(BaseModel):
    """Алерт роя"""
    id: int = Field(..., description="ID алерта")
    agent_id: Optional[str] = Field(None, description="ID агента")
    swarm_id: str = Field(..., description="ID роя")
    severity: str = Field(..., description="Серьезность")
    status: str = Field(..., description="Статус")
    message: str = Field(..., description="Сообщение")
    created_at: datetime = Field(..., description="Время создания")
    resolved_at: Optional[datetime] = Field(None, description="Время разрешения")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Метаданные")

# Log Models
class SwarmLogEntry(BaseModel):
    """Запись лога агента"""
    agent_id: str = Field(..., description="ID агента")
    timestamp: datetime = Field(..., description="Время записи")
    level: str = Field(..., description="Уровень лога")
    message: str = Field(..., description="Сообщение")
    module: Optional[str] = Field(None, description="Модуль")
    function: Optional[str] = Field(None, description="Функция")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Метаданные")

# Metrics Summary Models
class SwarmMetricsSummary(BaseModel):
    """Сводка метрик роя"""
    time_period: str = Field(..., description="Временной период")
    total_agents: int = Field(..., description="Общее количество агентов")
    active_agents: int = Field(..., description="Активные агенты")
    total_telemetry_points: int = Field(..., description="Общее количество точек телеметрии")
    average_response_time: float = Field(..., description="Среднее время отклика (мс)")
    error_rate: float = Field(..., description="Частота ошибок (%)")
    data_throughput: float = Field(..., description="Пропускная способность данных (MB/s)")
    health_score: float = Field(..., description="Общий показатель здоровья")
    top_locations: List[Dict[str, Any]] = Field(..., description="Топ местоположения")
    recent_alerts: List[SwarmAlert] = Field(..., description="Последние алерты")

# Bulk Operations Models
class BulkDeploymentResult(BaseModel):
    """Результат массового развертывания"""
    agent_id: str = Field(..., description="ID агента")
    success: bool = Field(..., description="Успешность")
    message: str = Field(..., description="Сообщение")
    deployment_id: Optional[str] = Field(None, description="ID развертывания")

class BulkOperationRequest(BaseModel):
    """Запрос на массовую операцию"""
    agent_ids: List[str] = Field(..., description="Список ID агентов")
    operation: str = Field(..., description="Операция")
    parameters: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Параметры")

class BulkOperationResponse(BaseModel):
    """Ответ на массовую операцию"""
    operation_id: str = Field(..., description="ID операции")
    total_agents: int = Field(..., description="Общее количество агентов")
    successful: int = Field(..., description="Успешных операций")
    failed: int = Field(..., description="Неудачных операций")
    results: List[BulkDeploymentResult] = Field(..., description="Результаты")
    started_at: datetime = Field(..., description="Время начала")
    completed_at: Optional[datetime] = Field(None, description="Время завершения")

# Validators
@validator('cpu_usage', 'memory_usage', 'disk_usage')
def validate_percentage(cls, v):
    """Валидация процентных значений"""
    if v < 0 or v > 100:
        raise ValueError('Percentage must be between 0 and 100')
    return v

@validator('health_score')
def validate_health_score(cls, v):
    """Валидация показателя здоровья"""
    if v < 0 or v > 100:
        raise ValueError('Health score must be between 0 and 100')
    return v

@validator('audio_quality')
def validate_audio_quality(cls, v):
    """Валидация качества аудио"""
    if v is not None and (v < 0 or v > 1):
        raise ValueError('Audio quality must be between 0 and 1')
    return v


