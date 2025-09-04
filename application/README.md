# IoT Sound Detection and Drone Detection POC

A proof-of-concept application for IoT sound detection and drone detection using serverless cloud architectures. This application provides a complete backend system for managing IoT devices, processing audio data, and detecting drones using machine learning.

## Features

### Core Functionality
- **Device Management**: Register, manage, and monitor IoT devices (drones, sensors, gateways)
- **Data Ingestion**: Receive telemetry data via HTTP and MQTT protocols
- **Audio Processing**: Upload and process audio files for drone detection
- **ML Analytics**: Real-time sound analysis and drone detection using machine learning
- **Alert System**: Generate alerts for drone detections and system anomalies
- **REST API**: Comprehensive REST API for all operations

### Technical Features
- **Multi-Protocol Support**: HTTP, MQTT, and WebSocket communication
- **Authentication & Authorization**: JWT tokens and API key authentication
- **Database**: PostgreSQL with SQLAlchemy ORM
- **Caching**: Redis for session management and caching
- **Background Processing**: Automated audio processing and device monitoring
- **Monitoring**: Prometheus metrics and health checks
- **Containerization**: Docker and Docker Compose support

## Architecture

The application follows a microservices architecture with the following components:

- **API Layer**: FastAPI-based REST API with automatic documentation
- **Service Layer**: Business logic services for devices, telemetry, alerts, and ML
- **Data Layer**: PostgreSQL database with Redis caching
- **ML Layer**: Machine learning services for sound analysis and drone detection
- **Communication Layer**: MQTT broker for IoT device communication
- **Monitoring Layer**: Prometheus metrics and health monitoring

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Python 3.11+ (for local development)

### Using Docker Compose (Recommended)

1. **Clone and navigate to the application directory**:
   ```bash
   cd application
   ```

2. **Start the application**:
   ```bash
   docker-compose up -d
   ```

3. **Access the application**:
   - API Documentation: http://localhost:8000/docs
   - Health Check: http://localhost:8000/health
   - Prometheus Metrics: http://localhost:9090
   - Grafana Dashboard: http://localhost:3000 (admin/admin)

### Local Development

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Set up environment variables**:
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

3. **Start the application**:
   ```bash
   python -m uvicorn app.main:app --reload
   ```

## API Usage

### Device Management

#### Register a Device
```bash
curl -X POST "http://localhost:8000/devices/" \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "drone-001",
    "device_type": "drone",
    "name": "Test Drone",
    "location": "Building A"
  }'
```

#### List Devices
```bash
curl -X GET "http://localhost:8000/devices/"
```

### Audio Processing

#### Upload Audio for Analysis
```bash
curl -X POST "http://localhost:8000/telemetry/audio" \
  -F "device_id=drone-001" \
  -F "audio_file=@audio_sample.wav" \
  -F "duration=2.0"
```

#### Process Audio for Drone Detection
```bash
curl -X POST "http://localhost:8000/analytics/process-audio" \
  -F "device_id=drone-001" \
  -F "audio_file=@audio_sample.wav"
```

### MQTT Communication

#### Check MQTT Status
```bash
curl -X GET "http://localhost:8000/mqtt/status"
```

#### Publish Device Command
```bash
curl -X POST "http://localhost:8000/mqtt/publish/device-command?device_id=drone-001" \
  -H "Content-Type: application/json" \
  -d '{"command": "start_recording", "duration": 10}'
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://iot_user:iot_password@postgres:5432/iot_sound_db` |
| `REDIS_URL` | Redis connection string | `redis://redis:6379/0` |
| `MQTT_BROKER` | MQTT broker hostname | `mqtt` |
| `SECRET_KEY` | JWT secret key | `your-secret-key-change-in-production` |
| `DEBUG` | Enable debug mode | `false` |

### Database Schema

The application uses the following main entities:
- **Devices**: IoT device information and status
- **TelemetryData**: Sensor and audio data from devices
- **Alerts**: System alerts and notifications
- **Users**: User accounts and authentication
- **APIKeys**: API key management for device authentication

## Machine Learning

The application includes ML capabilities for:
- **Drone Detection**: Audio-based drone detection using feature extraction
- **Sound Classification**: Classification of different sound types
- **Feature Extraction**: MFCC, spectral, and chroma features from audio

### ML Models

The application uses mock ML models for the POC. In production, you would:
1. Train actual models with real data
2. Implement model versioning and updates
3. Add model performance monitoring
4. Implement A/B testing for model comparison

## Monitoring and Observability

### Health Checks
- **Application Health**: `/health` - Overall system health
- **Database Health**: Included in health check
- **MQTT Health**: Connection status monitoring
- **ML Service Health**: Model loading and processing status

### Metrics
- **HTTP Metrics**: Request count, duration, status codes
- **Device Metrics**: Device count, online/offline status
- **ML Metrics**: Processing duration, detection accuracy
- **Alert Metrics**: Alert counts by type and severity

### Logging
- Structured logging with timestamps
- Different log levels (DEBUG, INFO, WARNING, ERROR)
- Request/response logging
- Error tracking and reporting

## Security

### Authentication
- JWT token-based authentication
- API key authentication for devices
- Role-based access control (Admin, Operator, Researcher)

### Data Protection
- Password hashing with bcrypt
- Secure token generation
- Input validation and sanitization
- CORS configuration

## Development

### Project Structure
```
application/
├── app/
│   ├── api/           # API routes and endpoints
│   ├── models/        # Database models
│   ├── schemas/       # Pydantic schemas
│   ├── services/      # Business logic services
│   ├── middleware/    # Custom middleware
│   └── main.py        # FastAPI application
├── storage/           # File storage directories
├── docker-compose.yml # Docker Compose configuration
├── Dockerfile         # Docker image definition
└── requirements.txt   # Python dependencies
```

### Adding New Features

1. **New API Endpoints**: Add routes in `app/api/routers/`
2. **New Services**: Implement business logic in `app/services/`
3. **New Models**: Add database models in `app/models/`
4. **New Schemas**: Define Pydantic schemas in `app/schemas/`

### Testing

The application includes basic health checks and error handling. For production use, add:
- Unit tests for services and utilities
- Integration tests for API endpoints
- Load testing for performance validation
- Security testing for vulnerability assessment

## Production Deployment

### Security Considerations
1. Change default passwords and secret keys
2. Enable MQTT authentication
3. Configure proper CORS settings
4. Use HTTPS for all communications
5. Implement rate limiting
6. Set up proper logging and monitoring

### Scaling
1. Use container orchestration (Kubernetes)
2. Implement database connection pooling
3. Add Redis clustering for high availability
4. Use load balancers for API endpoints
5. Implement horizontal scaling for ML processing

### Monitoring
1. Set up Prometheus and Grafana dashboards
2. Implement alerting for critical issues
3. Monitor resource usage and performance
4. Set up log aggregation and analysis

## License

This is a proof-of-concept application for educational and research purposes.

## Contributing

This is a POC application. For production use, consider:
- Adding comprehensive test coverage
- Implementing proper error handling
- Adding input validation and sanitization
- Implementing proper logging and monitoring
- Adding security hardening measures
