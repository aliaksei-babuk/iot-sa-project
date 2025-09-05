For SA Masters IoT project sound detection and C-UAC

## Table of Contents

- [Overview](#overview)
- [Solution Intent](#solution-intent)
	- [Business Context & Vision](#business-context--vision-solution-intent)
	- [Stakeholders & Benefits](#stakeholders--benefits)
	- [Core Value Proposition](#core-value-proposition)
	- [High Level Use Case Domains](#high-level-use-case-domains)
- [Users specification](#users-specification)
- [Use Journey definition](#use-journey-definition)
	- [Use Case 1: Real-Time Traffic Monitoring](#use-case-1-real-time-traffic-monitoring)
	- [Use Case 2: Public-Safety Siren Detection](#use-case-2-public-safety-siren-detection)
	- [Use Case 3: Urban Noise Mapping](#use-case-3-urban-noise-mapping)
	- [Use Case 4: Industrial Acoustic Monitoring](#use-case-4-industrial-acoustic-monitoring)
	- [Use Case 5: Environmental and Wildlife Monitoring](#use-case-5-environmental-and-wildlife-monitoring)
- [Functional Requirements](#functional-requerements)
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
- [Flowcharts](#flowcharts)
- [Non-Functional Requirements](#non-functional-requerements)
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
- [Components of Architecture](#components-of-architecture)
	- [High-Level System Architecture](#high-level-system-architecture)
	- [System Components View](#system-components-view)
	- [Detailed Serverless Components Architecture](#detailed-serverless-components-architecture)
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

## Solution Intent

To form an architectural design, first understand the content of the solution itself that is being designed. Since for educational purposes we do not plan to form a commercial solution, we will limit ourselves to its MVP-version. Therefore, in this issue, it is first necessary to determine the high-level requirements for the very idea (Solution Intent) of creating software for processing biometric information. For this, an approach to creating a Business Case was used, which involves formulating the main idea and global characteristics (Epics and Features) of the designed application. It is worth adding that due to certain limitations on the scope of the final qualification work, an abbreviated version of the business case was used.
For this, the following milestones were identified for creating a solution and the corresponding justification of its architectural design: determining business requirements for creating a solution; justifying system requirements; forming an architectural design for the MVP-product model
The subject area of the Solution design was chosen to be the field of work with Cloud‑Native Serverless Architecture for Real‑Time Sound Analytics in IoT. In recent years, it has been gaining increasing popularity. The use cases for software solutions providing the Real‑Time Sound Analytics in IoT are growing very rapidly. 

### Business Context & Vision (Solution Intent)

Real‑time analysis of environmental sound is critical for smart‑city scenarios such as traffic monitoring, public‑safety siren detection and urban noise mapping. However, the massive, highly‑variable sound event streams generated by distributed microphones and edge devices exceed the latency and cost envelopes of server‑centred architectures. This research proposes a cloud‑native serverless architecture that ingests, processes and analyses sound‑only IoT data with millisecond‑level end‑to‑end latency while maintaining pay‑per‑use cost efficiency. Building on recent advances in Function‑as‑a‑Service (FaaS), event‑driven pipelines and intelligent pre‑warming, we will design, implement and experimentally evaluate multi‑cloud prototypes on AWS Lambda and Azure Functions. Controlled workloads derived from UrbanSound8K, CitySoundscapes and ESC‑50 will be replayed through IoT simulators to benchmark cold‑start delay, throughput, accuracy of online audio classification and cost‑performance trade‑offs. Deep‑reinforcement‑learning (DRL) policies will be investigated for proactive scaling. The expected outcome is an empirically‑validated, cost‑aware orchestration blueprint and a set of open research artifacts (datasets, code, dashboards) that advance the state‑of‑the‑art in serverless audio analytics.

### Stakeholders & Benefits

| Stakeholder | Key Benefits |
|------|------------------|
|City Operations / DOT|Live traffic flow characterization; congestion and incident detection; heatmaps for planning|
|Public Safety (911, EMS)|Automatic siren detection, escalation triggers, and response ETA analytics.|
|Urban Planning / Environment|Noise mapping by street/zone; compliance reporting; long term trends.|
|Cloud / Platform Engineering|Multi cloud IaC, automated scaling, observability, and cost control.|
|Data Science / Research|High quality labeled streams; reproducible experiments; model performance dashboards.|

The Stakeholders & Benefits identifies the main groups who would use or rely on the cloud-native serverless sound analytics solution and highlights the value each group receives. City operations and transportation departments benefit from live traffic characterization and congestion detection to improve planning and response. Public safety agencies gain rapid siren detection and automatic alerts that can shorten emergency response times. Urban planners and environmental authorities obtain noise mapping and compliance insights that inform long-term policy decisions. Finally, cloud engineering and research teams benefit from reproducible multi-cloud deployments, improved observability, and high-quality datasets for experimentation and innovation.

### Core Value Proposition

The proposed architecture is designed to achieve millisecond-level end-to-end latency, a requirement that ensures timely and reliable operational decision-making in real-time urban environments. Beyond latency, the system emphasizes elastic scalability, maintaining resilience under bursty workloads of up to 10,000 requests per second without resorting to costly over-provisioning. From an economic perspective, the architecture is guided by the principle of cost efficiency, achieved through a pay-per-use model complemented by intelligent pre-warming strategies and adaptive memory allocation. Finally, the solution prioritizes portability, providing a multi-cloud blueprint that leverages Infrastructure-as-Code (Terraform, AWS CDK, Azure Bicep) to ensure reproducibility and seamless deployment across heterogeneous cloud providers.

### High Level Use Case Domains

| Domain | Example Uses | Stakeholder Value |
|------|------------------|------------------|
|Traffic monitoring	|Vehicle density estimation, honk events, congestion alerts	|Faster incident response; planning insights|
|Public safety siren detection |	Siren classification & georouting| Prioritization for emergency services|
|Urban noise mapping |	Zonal SPL/Leq estimates, temporal heatmaps |	Compliance & policy making|
|Industrial sound monitoring|	Anomaly detection on machinery spectra	| Reduced downtime; predictive maintenance|
|Environmental & wildlife |	Species / event acoustic detection |	Biodiversity studies; conservation actions|

The table of high-level use case domains outlines the breadth of applicability for cloud-native serverless sound analytics in contemporary smart-city and industrial contexts. One of the most prominent domains is traffic monitoring, where audio data such as vehicle noise and honking can be leveraged to infer traffic density, detect congestion, and provide actionable insights for transport authorities. In this domain, the proposed architecture contributes to reducing delays in incident detection and enables the generation of real-time traffic heatmaps that support both operational responses and long-term infrastructure planning. A second domain is public-safety siren detection, which involves automatically classifying emergency vehicle sirens and georouting them to dispatch centers. This application is particularly important because it shortens emergency response times, ensures faster prioritization of road clearance, and enhances situational awareness for emergency services.
The urban noise mapping domain addresses the growing concern of environmental sound pollution by producing zonal measurements of sound pressure levels and aggregated temporal heatmaps. Such data are valuable not only for compliance and regulatory purposes but also for guiding urban planning strategies that aim to improve citizens’ quality of life. Beyond city governance, industrial sound monitoring constitutes another relevant domain, where acoustic signatures of machinery can be analyzed to detect anomalies and prevent breakdowns. This proactive form of monitoring can reduce downtime, lower maintenance costs, and contribute to predictive maintenance frameworks already in use across Industry 4.0 settings.
Finally, the environmental and wildlife monitoring domain extends the scope of sound analytics to ecological applications. Acoustic event detection in natural habitats provides a non-intrusive means of tracking species presence, migration, and ecosystem health. Such insights are indispensable for conservation initiatives and biodiversity assessments, particularly in areas where traditional observation methods are impractical. Taken together, these use case domains illustrate the versatility and societal value of real-time sound analytics, demonstrating its potential to deliver both operational efficiency and long-term sustainability outcomes across diverse sectors.

## Users specification

The Users Specification table delineates the principal categories of stakeholders who will engage with the cloud-native serverless architecture for real-time sound analytics in IoT.

| Users Group |	Users’ Basic Needs |	Features of the Solution Explored |	Primary Use Cases |
|------|------------------|------------------|------------------|
|Municipal Authorities & City Operators	| Real-time traffic insights, noise compliance monitoring, long-term planning data |	Event-driven ingestion pipeline; real-time latency monitoring; Grafana dashboards |	Traffic flow monitoring, congestion detection, urban noise mapping|
|Public Safety & Emergency Services	| Rapid detection of sirens/alarms, situational awareness, reduced response times|	CNN-based audio classification (ESC-50 baseline); serverless pre-warming for low latency	| Siren detection and georouting, anomaly alerts in urban areas|
|Cloud & Platform Engineers	 |Cost control, scalability, multi-cloud deployment, reproducibility	|IaC templates (Terraform, AWS CDK, Azure Bicep); autoscaling with DRL (StableBaselines3 PPO); monitoring	| Deployment automation, cross-cloud testing, observability & cost optimization|
|Data Scientists & AI Researchers |	Reproducible datasets, metrics for evaluation, experimentation environment	| Pretrained CNN models; feature extraction with librosa; Jupyter notebooks; public GitHub repository |	Benchmarking classification accuracy, training/testing new models, publishing artifacts|
|Industrial Operators & Environmental Agencies|	Predictive maintenance, regulatory compliance, ecological monitoring|	Acoustic anomaly detection; workload replay simulator (UrbanSoundReplayer); metrics collection APIs	|Industrial machinery monitoring, compliance noise mapping, wildlife acoustic tracking|

The first group, municipal authorities and city operators, represents entities responsible for transportation management and environmental governance. Their primary need is the acquisition of timely and accurate acoustic data to inform operational decisions, enforce compliance, and plan long-term infrastructural investments. The solution addresses these needs by offering event-driven data ingestion, real-time latency monitoring, and intuitive dashboards that support both immediate interventions and strategic planning.
The second group, public safety and emergency services, relies on rapid acoustic classification for enhanced situational awareness. Their operational efficiency depends on the capacity to detect and interpret signals such as sirens or alarms in real time. The architecture’s integration of pretrained convolutional neural networks (CNNs), combined with serverless pre-warming strategies, ensures low-latency inference. In practice, this allows emergency services to shorten response times and prioritize interventions based on the geographical routing of detected acoustic events.
A third group, cloud and platform engineers, requires robust mechanisms for deployment, scalability, and cost optimization across multiple cloud providers. Their work is facilitated through Infrastructure-as-Code templates and reinforcement learning–driven autoscaling policies, which guarantee both reproducibility and cost efficiency. For these users, the system is not merely a research tool but an operational framework that ensures high availability and optimized resource allocation.
The fourth group, data scientists and AI researchers, depends on reproducible datasets and transparent evaluation pipelines. The solution provides them with open-source resources such as pretrained CNN models, Jupyter notebooks, and metrics repositories. By supporting rigorous benchmarking and iterative experimentation, the system enables researchers to improve classification accuracy and contribute new models back to the community.
Finally, industrial operators and environmental agencies constitute an extended but equally important user group. Industrial operators require predictive maintenance and anomaly detection in acoustic signatures of machinery, while environmental agencies depend on sound-based monitoring for regulatory compliance and ecological conservation. For both categories, the system provides advanced tools for anomaly detection, synthetic workload replay, and high-frequency metrics collection. These capabilities allow stakeholders to anticipate equipment failures, reduce downtime, and monitor biodiversity in non-intrusive ways.
Taken together, the table illustrates the multi-stakeholder relevance of the proposed solution. It demonstrates that real-time sound analytics, when implemented via a serverless multi-cloud architecture, serves not only operational efficiency but also regulatory, scientific, and environmental objectives. By addressing the specific needs of diverse user groups, the architecture maximizes societal, economic, and scientific impact, positioning itself as a versatile and sustainable technological innovation.

## Use Journey definition
 
Basic Uses Cases for the developed solution 
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Use_case_specification.png)


### Use Case 1: Real-Time Traffic Monitoring
| Field |	Description |
|------|------------------|
|Actors|City operators, traffic management systems|
|Preconditions|Microphones deployed at intersections and road segments stream audio to the IoT Hub.|
|Basic Flow|The serverless pipeline ingests audio, extracts spectral features using librosa, and classifies events such as honking or congestion indicators via pretrained CNN models. Metrics are aggregated into dashboards that provide near real-time situational awareness.|
|Postconditions|Operators receive alerts and visualizations that support immediate traffic control actions, such as rerouting or adjusting signal timing.|
|Primary Benefit|Reduced congestion and enhanced planning through evidence-based traffic management.|

![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Flow%20Chart%20for%20the%20UC-1.png)

The real-time traffic monitoring use case (UC-1) is designed to support urban mobility management by leveraging continuous acoustic data streams from distributed road-side microphones. The main flow involves the ingestion of audio via the IoT Hub, feature extraction through librosa, and subsequent classification of traffic-related acoustic events (e.g., honking, congestion signatures) using pretrained CNN models. Results are aggregated into dashboards that allow city operators to make evidence-based interventions. Potential exceptions include network disruptions that may cause partial data loss, misclassification due to overlapping sound events, or cloud function cold-start delays that temporarily degrade responsiveness. Nevertheless, the benefits are significant: traffic management authorities gain timely indicators for congestion mitigation, law enforcement agencies can respond more effectively to incidents, and urban planners obtain longitudinal datasets that inform infrastructure design 

### Use Case 2: Public-Safety Siren Detection
| Field |	Description |
|------|------------------|
|Actors|City operators, traffic management systems|
|Preconditions||
|Basic Flow||
|Postconditions||
|Primary Benefit||

### Use Case 3: Urban Noise Mapping
| Field |	Description |
|------|------------------|
|Actors|City operators, traffic management systems|
|Preconditions||
|Basic Flow||
|Postconditions||
|Primary Benefit||

### Use Case 4: Industrial Acoustic Monitoring
| Field |	Description |
|------|------------------|
|Actors|City operators, traffic management systems|
|Preconditions||
|Basic Flow||
|Postconditions||
|Primary Benefit||

### Use Case 5: Environmental and Wildlife Monitoring
| Field |	Description |
|------|------------------|
|Actors|City operators, traffic management systems|
|Preconditions||
|Basic Flow||
|Postconditions||
|Primary Benefit||

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


## Flowcharts
 TBD
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

### Detailed Serverless Components Architecture

![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Detailed%20Serverless%20Components%20Architecture.png)

### Package Diagram
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Package-Diagram-of-sUAV.png)

### Multi-Cloud Cross-Platform Deployment
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Docks/Multi-Cloud%20Cross-Platform%20Deployment.png)

Multi-Cloud Features:
- Unified API Layer: Abstraction across AWS Lambda, Azure Functions, and Google Cloud Functions
- Knative Orchestration: Kubernetes-native serverless for vendor independence
- Cross-Cloud Data Replication: Synchronized storage across providers
- Failover Mechanisms: Automatic switching between cloud providers
- Vendor-Agnostic Monitoring: Unified observability across platforms

### Azure Cloud Architecture
[Architecture](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Azure/azure_architecture.md)

### AWS Cloud Architecture 
[Architecture](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/AWS/aws_architecture.md)


## References 
Data pipeline approaches in serverless computing: a taxonomy, review, and research trends
https://journalofbigdata.springeropen.com/articles/10.1186/s40537-024-00939-0?utm_source=chatgpt.com