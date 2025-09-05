# Component View Diagram

```mermaid
graph TB
    subgraph "Device Management Layer"
        DR[DeviceRegistry]
        SM[SecurityManager]
        DG[DeviceGateway]
    end
    
    subgraph "Data Ingestion Layer"
        MB[MessageBroker]
        SV[SchemaValidator]
        DR2[DataRouter]
        DLQ[Dead Letter Queue]
    end
    
    subgraph "Processing Layer"
        AP[AudioProcessor]
        ML[MLInferenceEngine]
        AM[AlertManager]
    end
    
    subgraph "Storage Layer"
        HS[HotStorage]
        CS[ColdStorage]
        MS[MetadataStore]
        CM[ConfigurationManager]
    end
    
    subgraph "Presentation Layer"
        AG[APIGateway]
        DE[DashboardEngine]
        MS2[MonitoringService]
    end
    
    subgraph "External Systems"
        IoT[IoT Devices]
        USERS[Users/Stakeholders]
    end
    
    %% Device Management connections
    IoT --> DG
    DG --> DR
    DG --> SM
    SM --> MB
    
    %% Data Ingestion connections
    MB --> SV
    SV --> DR2
    SV --> DLQ
    DR2 --> AP
    
    %% Processing connections
    AP --> ML
    ML --> AM
    AM --> HS
    AM --> CS
    
    %% Storage connections
    HS --> MS
    CS --> MS
    CM --> AP
    CM --> ML
    CM --> AM
    
    %% Presentation connections
    MS --> AG
    AG --> USERS
    DE --> USERS
    MS2 --> DE
    MS2 --> AG
    
    %% Monitoring connections
    DR --> MS2
    MB --> MS2
    AP --> MS2
    ML --> MS2
    AM --> MS2
    HS --> MS2
    CS --> MS2
```

## Component Descriptions

### Device Management Layer
- **DeviceRegistry**: Handles IoT device onboarding, authentication, and lifecycle management
- **SecurityManager**: Enforces mTLS protocols and manages cryptographic keys
- **DeviceGateway**: Primary entry point for telemetry data from sensors and microphones

### Data Ingestion Layer
- **MessageBroker**: Implements event-driven message queuing with backpressure handling
- **SchemaValidator**: Performs real-time payload validation against predefined schemas
- **DataRouter**: Intelligently distributes validated audio streams to processing pipelines
- **Dead Letter Queue**: Handles invalid or corrupted data for manual inspection

### Processing Layer
- **AudioProcessor**: Handles real-time audio preprocessing and feature extraction
- **MLInferenceEngine**: Executes pretrained CNN models for sound classification
- **AlertManager**: Processes classification results and triggers notifications

### Storage Layer
- **HotStorage**: Real-time data access for immediate querying
- **ColdStorage**: Long-term archival for compliance and historical analysis
- **MetadataStore**: Maintains indexes and searchable metadata
- **ConfigurationManager**: Handles dynamic configuration updates

### Presentation Layer
- **APIGateway**: Provides unified RESTful APIs with authentication
- **DashboardEngine**: Generates interactive visualizations and monitoring interfaces
- **MonitoringService**: Aggregates metrics, logs, and traces from all components
