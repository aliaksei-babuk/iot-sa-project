For SA Masters IoT project sound detection and C-UAC

## Components

- [Overview](#overview)
- [Functional Requerements](#functional-requerements)
	- [FR-01: Device Onboarding](#fr-01-device-onboarding)
	- [FR-02: Secure Communications](#fr-02-secure-communications)
	- [FR-03: Data Ingestion](#fr-03-data-ingestion)
	- [FR-04: Data Validation](#fr-04-data-validation)
	- [FR-05: Data Storage](#fr-05-data-storage)
	- [FR-06: Analytics and Alerts](#fr-06-analytics-and-alerts)
	- [FR-07: Dashboards and APIs](#fr-07-dashboards-and-apis)
	- [FR-08: Data Lifecycle Management](#fr-08-data-lifecycle-management)
	- [FR-09: Admin and RBAC](#fr-09-admin-and-rbac)
	- [FR-10: Failure Handling](#fr-10-failure-handling)
- [Use cases](#use-cases)
	- [General system work](#general-system-work)
	- [Device Lifecycle](#device-lifecycle)
	- [Drone Detection and Alerting](#drone-detection-and-alerting)
- [Flowcharts](#flowcharts)
	- [Device registration](#device-registration)
	- [Device sends telemetry](#device-sends-telemetry)
	- [User queries data](#user-queries-data)
- [Non-Functional Requerements](#non-functional-requerements)
	- [NFR-01: Performance](#nfr-01-performance)
	- [NFR-02: Scalability](#nfr-02-scalability)
	- [NFR-03: Availability](#nfr-03-availability)
	- [NFR-04: Reliability](#nfr-04-reliability)
	- [NFR-05: Security](#nfr-05-security)
	- [NFR-06: Privacy/Compliance](#nfr-06-privacycompliance)
	- [NFR-07: Interoperability](#nfr-07-interoperability)
	- [NFR-08: Observability](#nfr-08-observability)
	- [NFR-09: Cost](#nfr-09-cost)
	- [NFR-10: Maintainability](#nfr-10-maintainability)
	- [NFR-11: Portability](#nfr-11-portability)
	- [NFR-12: Data Quality](#nfr-12-data-quality)
- [Components of architecture](#components-of-architecture)
	- [High-Level System Architecture](#high-level-system-architecture)
	- [System Components View](#system-components-view)
	- [Package Diagram](#package-diagram)
	- [Multi-Cloud Cross-Platform Deployment](#multi-cloud-cross-platform-deployment)
	- [Azure Cloud Architecture](#azure-cloud-architecture)
	- [AWS Cloud Architecture](#aws-cloud-architecture)
- [References](#references)


## Overview
Research on serverless cloud architectures for sound analytics and drone detection in IoT contexts has grown, driven by the need for scalable, low-latency processing of acoustic data from edge devices. Serverless computing, often implemented via Function-as-a-Service (FaaS), enables event-driven execution where functions are triggered by IoT sensor data (e.g., audio streams from microphones on drones or ground sensors), scaling automatically without infrastructure management. However, direct integrations of serverless with acoustic drone detection remain emerging, with most studies focusing on related areas: serverless in IoT for edge analytics, acoustic-based drone detection using ML/IoT, and general serverless challenges.
Key research themes include:

Serverless in IoT for Analytics: Studies explore edge-fog-cloud hierarchies to process IoT data, reducing latency for real-time applications like audio analysis.
Sound Analytics for Drone Detection: Acoustic sensors capture drone propeller noise, processed via ML models (e.g., CNN, RNN) for detection and classification, often integrated with IoT networks.
Architecture Features: Common features emphasize scalability, cost-efficiency, and integration with IoT/edge computing, but face portability hurdles.

## Functional Requerements 
### FR-01: Device Onboarding
Description: System shall provision and register IoT devices (drones/sensors) securely using a unified API.
Rationale: Enables automated enrollment to scale deployments without manual intervention, addressing vendor lock-in via cross-platform compatibility.
Inputs/Outputs: Input: Device ID, credentials; Output: Registration token, endpoint config.
Acceptance Criteria: Device connects successfully within 30s; verified via API response 200 OK and log entry.

### FR-02: Secure Communications
Description: System shall enforce mTLS for all device-to-cloud interactions over MQTT/HTTP.
Rationale: Protects against eavesdropping and ensures data integrity in sensitive drone detection scenarios.
Inputs/Outputs: Input: Encrypted payload; Output: Acknowledgment receipt.
Acceptance Criteria: All sessions use TLS 1.3+; fail unencrypted attempts with error code.

### FR-03: Data Ingestion
Description: System shall ingest telemetry (audio streams/events) via gateways with backpressure handling.
Rationale: Handles bursty data from multiple devices efficiently in serverless setup.
Inputs/Outputs: Input: JSON/audio payload; Output: Ingestion ID.
Acceptance Criteria: Processes 100 events/sec without loss; confirmed by queue metrics.

### FR-04: Data Validation
Description: System shall validate incoming data against schema and QoS rules.
Rationale: Ensures data quality for accurate sound analytics and drone classification.
Inputs/Outputs: Input: Raw telemetry; Output: Validated data or DLQ routing.
Acceptance Criteria: 99% valid data pass; invalid routed to DLQ with alert.

### FR-05: Data Storage
Description: System shall store validated data in hot/cold paths with idempotency.
Rationale: Supports querying and long-term retention for research/analysis.
Inputs/Outputs: Input: Validated payload; Output: Storage reference.
Acceptance Criteria: Data retrievable within 1s (hot), 10s (cold); duplicate handling verified.

### FR-06: Analytics and Alerts
Description: System shall perform ML-based sound analytics (e.g., CNN for drone detection) and trigger alerts.
Rationale: Enables real-time anomaly detection in IoT streams.
Inputs/Outputs: Input: Stored/stream data; Output: Alert notification (SMS/email/webhook).
Acceptance Criteria: Detection accuracy >95%; alert latency <500ms.

### FR-07: Dashboards and APIs
Description: System shall provide unified API and dashboards for querying data and visualizations.
Rationale: Facilitates researcher/operator access across clouds.
Inputs/Outputs: Input: Query parameters; Output: JSON results/dashboard view.
Acceptance Criteria: API response <200ms; dashboard loads in <3s.

### FR-08: Data Lifecycle Management
Description: System shall enforce retention policies and data purging.
Rationale: Complies with GDPR and optimizes storage costs.
Inputs/Outputs: Input: Policy config; Output: Purge confirmation.
Acceptance Criteria: Data deleted after 30 days; audited via logs.

### FR-09: Admin and RBAC
Description: System shall manage user roles and policies via unified API.
Rationale: Ensures secure access control for admins/operators/researchers.
Inputs/Outputs: Input: Role assignment; Output: Access token.
Acceptance Criteria: Unauthorized access denied; audited.

### FR-10: Failure Handling
Description: System shall route failures to DLQs and retry idempotent operations.
Rationale: Maintains reliability in distributed IoT environments.
Inputs/Outputs: Input: Failed event; Output: Retry or alert.
Acceptance Criteria: 99% recovery rate; no data loss.

## Use cases

### General system work
![General system work](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Cloud%20IoT%20System%20%E2%80%93%20Use%20Case.png)
### Device Lifecycle
![Device Lifecycle](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Device%20Lifecycle%20Use%20Cases.png)
### Drone Detection and Alerting
![Drone Detection and Alerting](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Use%20Case%20Diagram%20for%20Drone%20Detection%20and%20Alerting.png)

## Flowcharts

### Device registration
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/device-registration-Flowchart-initial.svg)
### Device sends telemetry
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Device-sends-telemetry-Flowchart-initial.svg)
### User queries data
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/User-queries-data-Flowchart-initial.svg)

## Non-Functional Requerements 

### NFR-01: Performance
Target/Metric: p95 end-to-end ingest latency ≤ 100ms at 100 events/sec.
Verification: Benchmark tests with simulated loads.
Priority: Must; Risk: High (mitigation: optimize serverless cold starts).

### NFR-02: Scalability
Target/Metric: Auto-scale to 10,000 devices without degradation (>99% throughput).
Verification: Load testing in hybrid cloud.
Priority: Must; Risk: Med (mitigation: use container orchestration).

### NFR-03: Availability
Target/Metric: 99.9% uptime, multi-region failover <1min.
Verification: Chaos engineering tests.
Priority: Must; Risk: High (mitigation: redundant deployments).

### NFR-04: Reliability
Target/Metric: <0.1% data loss, with idempotency and retries.
Verification: Fault injection simulations.
Priority: Must; Risk: Med (mitigation: DLQs).

### NFR-05: Security
Target/Metric: mTLS enforcement, zero trust; no vulnerabilities in OWASP top 10.
Verification: Pen-tests and audits.
Priority: Must; Risk: High (mitigation: regular scans).

### NFR-06: Privacy/Compliance
Target/Metric: GDPR compliant; anonymize PII in audio data.
Verification: Conformance audits.
Priority: Must; Risk: High (mitigation: data masking tools).

### NFR-07: Interoperability
Target/Metric: Support MQTT/HTTP/AMQP; unified API for cross-cloud.
Verification: Integration tests across AWS/Azure/GCP.
Priority: Should; Risk: Med (mitigation: abstraction layers).

### NFR-08: Observability
Target/Metric: Full metrics/logs/traces; queryable in <5s.
Verification: Monitoring dashboard validation.
Priority: Should; Risk: Low (mitigation: open-source tools).

### NFR-09: Cost
Target/Metric: ≤ $0.01 per event processed.
Verification: Monthly cost reports.
Priority: Could; Risk: Low (mitigation: auto-scaling).

### NFR-10: Maintainability
Target/Metric: Code modularity; deploy updates <5min downtime.
Verification: CI/CD pipeline tests.
Priority: Should; Risk: Low (mitigation: microservices).

### NFR-11: Portability
Target/Metric: Migrate between clouds <1hr; no vendor-specific code.
Verification: Cross-platform deployment tests.
Priority: Must; Risk: High (mitigation: unified API).

### NFR-12: Data Quality
Target/Metric: >98% accuracy in validation; handle noisy audio.
Verification: Sample audits.
Priority: Should; Risk: Med (mitigation: ML preprocessing).

## Components of architecture

### High-Level System Architecture
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/High-Level%20System%20Architecture.png)

### System Components View
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/System%20Components%20View.png)

### Package Diagram
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Package-Diagram-of-sUAV.png)

### Multi-Cloud Cross-Platform Deployment
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Package-Diagram-of-sUAV.png)

### Azure Cloud Architecture
[Architecture](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Azure/azure_architecture.md)

### AWS Cloud Architecture 
[Architecture](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/AWS/aws_architecture.md)


## References 
Data pipeline approaches in serverless computing: a taxonomy, review, and research trends
https://journalofbigdata.springeropen.com/articles/10.1186/s40537-024-00939-0?utm_source=chatgpt.com