# Azure IoT Sound Analytics - Terraform Deployment

This Terraform configuration deploys a comprehensive serverless architecture for real-time sound analytics in IoT environments on Microsoft Azure.

## Architecture Overview

The deployment creates a modular, scalable architecture with the following components:

- **Networking**: Virtual Network with private subnets and security groups
- **IoT Services**: IoT Hub, Event Hubs, and Service Bus for data ingestion
- **Compute**: Azure Functions, Container Apps, and Logic Apps for processing
- **Storage**: Cosmos DB, SQL Database, Blob Storage, and Redis Cache
- **Analytics**: Stream Analytics, Machine Learning workspace, and Power BI
- **Security**: Key Vault, Security Center, and Azure AD integration
- **Monitoring**: Log Analytics, Application Insights, and alerting
- **API**: API Management, Front Door, and Web Apps for external access

## Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0 installed
- Azure subscription with appropriate permissions
- Azure AD tenant access

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Azure/terraform
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Create a terraform.tfvars file**:
   ```hcl
   environment = "dev"
   location = "East US"
   
   # Optional: Override default values
   iot_hub_sku = "S1"
   iot_hub_capacity = 1
   cosmos_db_throughput = 400
   sql_database_sku = "S0"
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**:
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment name (dev, staging, prod) | `dev` |
| `location` | Azure region for resources | `East US` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `iot_hub_sku` | SKU for IoT Hub | `S1` |
| `iot_hub_capacity` | Capacity for IoT Hub | `1` |
| `cosmos_db_throughput` | Throughput for Cosmos DB | `400` |
| `sql_database_sku` | SKU for SQL Database | `S0` |
| `function_app_plan_sku` | SKU for Function App Plan | `Y1` |
| `enable_monitoring` | Enable monitoring and alerting | `true` |
| `enable_security_center` | Enable Azure Security Center | `true` |
| `enable_ddos_protection` | Enable DDoS Protection | `false` |
| `retention_days` | Log retention days | `30` |
| `backup_retention_days` | Backup retention days | `7` |

## Module Structure

```
Azure/terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars        # Variable values (create this)
└── modules/
    ├── networking/         # VNet, subnets, NSGs
    ├── iot_services/       # IoT Hub, Event Hubs, Service Bus
    ├── compute/            # Functions, Container Apps, Logic Apps
    ├── storage/            # Cosmos DB, SQL Database, Blob Storage
    ├── analytics/          # Stream Analytics, ML, Power BI
    ├── security/           # Key Vault, Security Center, Azure AD
    ├── monitoring/         # Log Analytics, Application Insights
    └── api/                # API Management, Front Door, Web Apps
```

## Key Features

### Security
- **Zero Trust Architecture**: All communications encrypted
- **Private Endpoints**: Secure connectivity to PaaS services
- **Key Vault**: Centralized secrets management
- **Azure AD Integration**: Identity and access management
- **Security Center**: Continuous security monitoring

### Scalability
- **Auto-scaling**: Functions and Container Apps scale automatically
- **Event-driven**: Serverless architecture for cost efficiency
- **Multi-tier Storage**: Hot, warm, and cold data paths
- **Load Balancing**: Front Door for global distribution

### Monitoring
- **Application Insights**: Real-time application monitoring
- **Log Analytics**: Centralized logging and analysis
- **Custom Dashboards**: Operational visibility
- **Alerting**: Proactive issue detection

### Compliance
- **GDPR Ready**: Data privacy and protection
- **SOC 2**: Security and availability controls
- **ISO 27001**: Information security management
- **Audit Logging**: Comprehensive activity tracking

## Cost Optimization

The architecture is designed for cost efficiency:

- **Serverless Compute**: Pay-per-use model
- **Data Lifecycle Management**: Automatic tiering
- **Reserved Instances**: For predictable workloads
- **Auto-scaling**: Right-size resources based on demand

Estimated monthly cost for 1000 devices: ~$1,300

## Deployment Phases

### Phase 1: Foundation (Months 1-2)
- Infrastructure setup
- Security implementation
- Basic monitoring
- CI/CD pipeline

### Phase 2: Core Services (Months 3-4)
- IoT integration
- Data processing pipeline
- Storage implementation
- API development

### Phase 3: Advanced Features (Months 5-6)
- ML integration
- Analytics platform
- User interface
- Integration testing

### Phase 4: Production (Months 7-8)
- Performance optimization
- Security hardening
- Disaster recovery
- Go-live

## Disaster Recovery

- **Multi-region Deployment**: Primary and DR regions
- **Data Replication**: Cross-region data sync
- **Automated Failover**: RTO < 15 minutes
- **Backup Strategy**: RPO < 5 minutes

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure Azure AD permissions are correct
2. **Resource Limits**: Check subscription quotas
3. **Network Issues**: Verify VNet configuration
4. **Storage Access**: Confirm private endpoint setup

### Debug Commands

```bash
# Check Terraform state
terraform state list

# View specific resource
terraform state show <resource_name>

# Import existing resource
terraform import <resource_type>.<name> <resource_id>
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources. Ensure you have backups of important data.

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review Azure documentation
3. Open an issue in the repository
4. Contact the development team

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Changelog

### v1.0.0
- Initial release
- Complete Azure infrastructure
- All modules implemented
- Documentation created
