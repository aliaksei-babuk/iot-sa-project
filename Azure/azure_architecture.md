# Azure realization (service mapping)
• Ingress: Azure IoT Hub / Event Hubs; Private Endpoints + Azure AD for auth.
• Processing: Azure Functions (Premium) for ingestion/validation; Azure Container Apps for feature extraction; Azure ML for model registry & training.
• Storage: Azure Blob (hot/cool/archive), Data Lake Gen2; Cosmos DB for metadata/queries.
• Analytics & Alerts: Azure Stream Analytics or Event Grid + Logic Apps; Azure Monitor/Log Analytics for observability.
• North-bound: Azure API Management; Azure Front Door.
• Security: Key Vault, Managed Identities, Azure Policy, Private Link, Defender for Cloud.

# service mapping diagram
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/Azure/deploy_azure.png)


# References:
https://learn.microsoft.com/en-us/azure/architecture/serverless/event-hubs-functions/event-hubs-functions
 
https://learn.microsoft.com/en-us/azure/architecture/solution-ideas/articles/project-15-iot-sustainability?utm_source=chatgpt.com