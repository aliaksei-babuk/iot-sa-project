# 🤖 Управление Роем IoT Агентов

## Обзор

Система управления роем IoT агентов для звуковой аналитики позволяет развертывать, мониторить и управлять множественными устройствами как единым роем. Каждый агент собирает аудиоданные, обрабатывает их с помощью ML моделей и передает результаты в облако.

## 🏗️ Архитектура Роя

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Agent 001     │    │   Agent 002     │    │   Agent 003     │
│  (Москва)       │    │  (СПб)          │    │  (Казань)       │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Микрофон  │ │    │ │   Микрофон  │ │    │ │   Микрофон  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   ML Model  │ │    │ │   ML Model  │ │    │ │   ML Model  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   IoT Hub   │ │    │ │   IoT Hub   │ │    │ │   IoT Hub   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Azure Cloud   │
                    │                 │
                    │ ┌─────────────┐ │
                    │ │  IoT Hub    │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │  Analytics  │ │
                    │ └─────────────┘ │
                    │ ┌─────────────┐ │
                    │ │ Monitoring  │ │
                    │ └─────────────┘ │
                    └─────────────────┘
```

## 🚀 Быстрый Старт

### 1. Развертывание Инфраструктуры

```bash
# Перейти в директорию Terraform
cd Azure/terraform

# Развернуть инфраструктуру роя
./swarm-manager.sh deploy-infrastructure
```

### 2. Регистрация Агентов

```bash
# Зарегистрировать агента в Москве
./swarm-manager.sh register-agent "agent-moscow-001" "Moscow, Russia"

# Зарегистрировать агента в СПб
./swarm-manager.sh register-agent "agent-spb-001" "St. Petersburg, Russia"

# Зарегистрировать агента в Казани
./swarm-manager.sh register-agent "agent-kazan-001" "Kazan, Russia"
```

### 3. Развертывание Агентов

```bash
# Развернуть агента на устройстве (Raspberry Pi)
./swarm-manager.sh deploy-agent "agent-moscow-001" "192.168.1.100" "pi"

# Развернуть агента на другом устройстве
./swarm-manager.sh deploy-agent "agent-spb-001" "192.168.1.101" "pi"
```

### 4. Мониторинг Роя

```bash
# Просмотреть список агентов
./swarm-manager.sh list-agents

# Мониторить телеметрию в реальном времени
./swarm-manager.sh monitor-swarm
```

## 📋 Команды Управления

### Основные Команды

| Команда | Описание | Пример |
|---------|----------|--------|
| `deploy-infrastructure` | Развернуть инфраструктуру роя | `./swarm-manager.sh deploy-infrastructure` |
| `register-agent <id> <location>` | Зарегистрировать агента | `./swarm-manager.sh register-agent "agent-001" "Moscow"` |
| `deploy-agent <id> <ip> <user>` | Развернуть агента на устройстве | `./swarm-manager.sh deploy-agent "agent-001" "192.168.1.100" "pi"` |
| `list-agents` | Список всех агентов | `./swarm-manager.sh list-agents` |
| `monitor-swarm` | Мониторинг телеметрии | `./swarm-manager.sh monitor-swarm` |
| `update-config` | Обновить конфигурацию | `./swarm-manager.sh update-config` |
| `remove-agent <id>` | Удалить агента | `./swarm-manager.sh remove-agent "agent-001"` |

### API Управления

```bash
# Получить статус роя
curl -X GET "http://localhost:8000/api/v1/swarm/status" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Создать нового агента
curl -X POST "http://localhost:8000/api/v1/swarm/agents" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "agent_id": "agent-001",
    "swarm_id": "sound-analytics-swarm",
    "agent_type": "sound-agent",
    "location": "Moscow, Russia",
    "version": "2.0.0"
  }'

# Развернуть агента
curl -X POST "http://localhost:8000/api/v1/swarm/agents/agent-001/deploy" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "agent_id": "agent-001",
    "device_ip": "192.168.1.100",
    "ssh_user": "pi",
    "ssh_key": "YOUR_SSH_KEY"
  }'

# Получить метрики здоровья агента
curl -X GET "http://localhost:8000/api/v1/swarm/agents/agent-001/health?hours=24" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔧 Конфигурация Агентов

### Базовая Конфигурация

```json
{
  "swarmId": "sound-analytics-swarm",
  "agentId": "agent-001",
  "version": "2.0.0",
  "audioSettings": {
    "sampleRate": 22050,
    "duration": 2.0,
    "channels": 1,
    "format": "wav"
  },
  "mlSettings": {
    "modelVersion": "2.0.0",
    "confidenceThreshold": 0.7,
    "enableRealTimeProcessing": true
  },
  "networkSettings": {
    "retryAttempts": 3,
    "timeoutSeconds": 30,
    "enableCompression": true
  }
}
```

### Настройки Мониторинга

```json
{
  "healthMonitoring": {
    "enabled": true,
    "reportInterval": 60,
    "metrics": [
      "cpu_usage",
      "memory_usage",
      "disk_usage",
      "network_latency",
      "audio_quality",
      "ml_processing_time"
    ],
    "alerts": {
      "cpuThreshold": 80,
      "memoryThreshold": 85,
      "diskThreshold": 90,
      "latencyThreshold": 1000
    }
  }
}
```

## 📊 Мониторинг и Аналитика

### Дашборд Роя

- **Статус агентов**: Активные, неактивные, с ошибками
- **Метрики производительности**: CPU, память, диск
- **Классификация звуков**: Распределение по типам
- **Качество данных**: Показатели качества аудио
- **Сетевая статистика**: Задержки, пропускная способность

### Алерты

- **Агент офлайн**: Агент не отвечает более 5 минут
- **Высокая нагрузка**: CPU > 80% или память > 85%
- **Ошибки ML**: Низкое качество классификации
- **Сетевые проблемы**: Высокая задержка или потеря пакетов

### Логи

```bash
# Просмотр логов агента
curl -X GET "http://localhost:8000/api/v1/swarm/agents/agent-001/logs?hours=24&level=ERROR" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🔒 Безопасность

### Аутентификация

- **IoT Hub**: SAS токены для каждого агента
- **API**: JWT токены для управления
- **SSH**: Ключи для развертывания

### Шифрование

- **В пути**: TLS 1.2 для всех соединений
- **В покое**: Шифрование данных в Cosmos DB
- **Аудио**: Шифрование аудиоданных

### Сетевая Безопасность

- **Private Endpoints**: Для критических сервисов
- **NSG**: Правила сетевой безопасности
- **VPN**: Защищенное подключение агентов

## 🚨 Устранение Неполадок

### Агент не подключается

```bash
# Проверить статус агента
./swarm-manager.sh list-agents

# Проверить логи агента
curl -X GET "http://localhost:8000/api/v1/swarm/agents/agent-001/logs" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Перезапустить агента
curl -X POST "http://localhost:8000/api/v1/swarm/agents/agent-001/restart" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Проблемы с развертыванием

```bash
# Проверить SSH подключение
ssh pi@192.168.1.100

# Проверить права доступа
ls -la /opt/iot-sound-agent/

# Проверить сервис
sudo systemctl status iot-sound-agent
```

### Низкое качество данных

```bash
# Проверить метрики здоровья
curl -X GET "http://localhost:8000/api/v1/swarm/agents/agent-001/health" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Обновить конфигурацию
curl -X PUT "http://localhost:8000/api/v1/swarm/configuration" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "audioSettings": {
      "sampleRate": 44100,
      "duration": 3.0
    }
  }'
```

## 📈 Масштабирование

### Горизонтальное Масштабирование

```bash
# Массовое развертывание агентов
curl -X POST "http://localhost:8000/api/v1/swarm/agents/bulk-deploy" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '[
    {
      "agent_id": "agent-001",
      "device_ip": "192.168.1.100",
      "ssh_user": "pi"
    },
    {
      "agent_id": "agent-002", 
      "device_ip": "192.168.1.101",
      "ssh_user": "pi"
    }
  ]'
```

### Вертикальное Масштабирование

- **Увеличение пропускной способности IoT Hub**
- **Масштабирование Function Apps**
- **Увеличение емкости Cosmos DB**

## 🎯 Лучшие Практики

### Развертывание

1. **Тестирование**: Всегда тестируйте на одном агенте перед массовым развертыванием
2. **Версионирование**: Используйте семантическое версионирование для агентов
3. **Откат**: Подготовьте план отката для каждого развертывания

### Мониторинг

1. **Алерты**: Настройте алерты для критических метрик
2. **Логи**: Централизованное логирование всех агентов
3. **Дашборды**: Регулярно проверяйте дашборды мониторинга

### Безопасность

1. **Ротация ключей**: Регулярно обновляйте ключи доступа
2. **Обновления**: Своевременно обновляйте агентов
3. **Аудит**: Ведите аудит всех операций

## 📚 Дополнительные Ресурсы

- [Azure IoT Hub Documentation](https://docs.microsoft.com/en-us/azure/iot-hub/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Documentation](https://docs.docker.com/)

## 🤝 Поддержка

Для получения поддержки:

1. Проверьте [FAQ](FAQ.md)
2. Создайте [Issue](https://github.com/your-repo/issues)
3. Обратитесь к [документации](README.md)

---

**Версия**: 2.0.0  
**Последнее обновление**: $(date)  
**Автор**: IoT Sound Analytics Team


