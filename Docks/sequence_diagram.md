# UML Sequence Diagram

```mermaid
sequenceDiagram
    participant MS as MicrophoneSensor
    participant DG as DeviceGateway
    participant SM as SecurityManager
    participant MB as MessageBroker
    participant SV as SchemaValidator
    participant DR as DataRouter
    participant AP as AudioProcessor
    participant ML as MLInferenceEngine
    participant AM as AlertManager
    participant HS as HotStorage
    participant CS as ColdStorage
    participant AG as APIGateway
    participant DE as DashboardEngine
    participant MS2 as MonitoringService

    Note over MS,MS2: Device Connection and Authentication
    MS->>DG: connect()
    DG->>SM: authenticate(deviceId, credentials)
    SM-->>DG: connection token
    DG-->>MS: connection established

    Note over MS,MS2: Data Ingestion and Validation
    MS->>DG: sendTelemetry(audioData)
    DG->>MB: queue(audioData)
    MB->>SV: validate(payload)
    
    alt Valid Data
        SV->>DR: route(audioData)
        DR->>AP: process(audioData)
    else Invalid Data
        SV->>MB: routeToDLQ(invalidData)
    end

    Note over MS,MS2: Audio Processing and ML Inference
    AP->>AP: normalizeAudio()
    AP->>AP: extractSpectralFeatures()
    AP->>ML: preprocessInput(features)
    ML->>ML: loadModel()
    ML->>ML: classifySound()
    ML-->>AP: classification results + confidence

    Note over MS,MS2: Alert Processing and Storage
    AP->>AM: processResults(classification)
    AM->>AM: evaluateRules(confidence)
    
    alt Alert Conditions Met
        AM->>AM: sendNotification(SMS, email, webhook)
        AM->>HS: storeAlert(metadata)
    end
    
    AM->>HS: storeResults(processedData)
    HS->>CS: archiveOldData()

    Note over MS,MS2: Data Presentation and Monitoring
    AG->>HS: queryData()
    HS-->>AG: returnData()
    AG->>DE: generateVisualization()
    DE-->>AG: dashboard data
    
    Note over MS,MS2: Monitoring and Observability
    MS->>MS2: metrics
    DG->>MS2: logs
    AP->>MS2: traces
    ML->>MS2: performance data
    AM->>MS2: alert metrics
    HS->>MS2: storage metrics
    CS->>MS2: archival metrics
    MS2->>DE: aggregated metrics
```

## Sequence Flow Description

### 1. Device Connection and Authentication
- MicrophoneSensor initiates connection to DeviceGateway
- SecurityManager authenticates device using mTLS protocols
- Connection token is returned for secure communication

### 2. Data Ingestion and Validation
- Audio data is sent from sensor to DeviceGateway
- MessageBroker queues the data with backpressure handling
- SchemaValidator performs real-time payload validation
- Valid data is routed to processing pipeline, invalid data goes to DLQ

### 3. Audio Processing and ML Inference
- AudioProcessor normalizes and extracts spectral features
- MLInferenceEngine loads pretrained CNN model
- Sound classification is performed with confidence scoring
- Results are returned for further processing

### 4. Alert Processing and Storage
- AlertManager evaluates business rules and confidence thresholds
- Notifications are sent through multiple channels if conditions are met
- Data is stored in both hot and cold storage systems
- Data lifecycle management is applied

### 5. Data Presentation and Monitoring
- APIGateway queries data from storage systems
- DashboardEngine generates real-time visualizations
- MonitoringService aggregates metrics from all components
- Comprehensive observability is maintained throughout the flow
