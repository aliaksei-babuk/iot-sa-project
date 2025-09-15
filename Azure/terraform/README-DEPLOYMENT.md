# Azure IoT Sound Analytics - Deployment Guide

This guide provides comprehensive instructions for deploying the Azure IoT Sound Analytics infrastructure using Terraform.

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI** - Install and login
   ```bash
   # Install Azure CLI (macOS)
   brew install azure-cli
   
   # Login to Azure
   az login
   
   # Set subscription (optional)
   az account set --subscription "Your Subscription Name"
   ```

2. **Terraform** - Install Terraform >= 1.0
   ```bash
   # Install Terraform (macOS)
   brew install terraform
   
   # Verify installation
   terraform version
   ```

3. **Additional Tools**
   ```bash
   # Install jq for JSON processing
   brew install jq
   
   # Install curl (usually pre-installed)
   # curl --version
   ```

### One-Command Deployment

```bash
# Make scripts executable
chmod +x deploy-azure.sh config-manager.sh

# Setup development environment
./config-manager.sh setup dev

# Deploy infrastructure
./deploy-azure.sh deploy
```

## 📋 Detailed Deployment Steps

### Step 1: Environment Setup

1. **Create environment configuration**
   ```bash
   # Create development environment
   ./config-manager.sh create dev
   
   # Create staging environment
   ./config-manager.sh create staging
   
   # Create production environment
   ./config-manager.sh create prod
   ```

2. **Customize configuration**
   ```bash
   # Edit the configuration file
   nano config/terraform-dev.tfvars
   
   # Key variables to customize:
   # - admin_email: Your email address
   # - location: Azure region
   # - iot_hub_sku: IoT Hub tier (F1, S1, S2, S3)
   # - sql_database_sku: Database tier
   ```

3. **Generate secure passwords**
   ```bash
   ./config-manager.sh generate-passwords
   ```

### Step 2: Deploy Infrastructure

1. **Plan deployment**
   ```bash
   ./deploy-azure.sh plan
   ```

2. **Apply deployment**
   ```bash
   ./deploy-azure.sh apply
   ```

3. **Check deployment status**
   ```bash
   ./deploy-azure.sh status
   ```

### Step 3: Post-Deployment Configuration

1. **View deployment outputs**
   ```bash
   ./deploy-azure.sh outputs
   ```

2. **Setup monitoring**
   ```bash
   ./deploy-azure.sh setup-monitoring
   ```

3. **Get cost estimate**
   ```bash
   ./deploy-azure.sh cost-estimate
   ```

## 🔧 Configuration Management

### Environment Management

```bash
# List available environments
./config-manager.sh list

# Switch to different environment
./config-manager.sh switch staging

# Backup current configuration
./config-manager.sh backup dev

# Restore from backup
./config-manager.sh restore config/backup-dev-20240101-120000.tfvars
```

### Configuration Files

- **`terraform.tfvars`** - Active configuration (symlink)
- **`config/terraform-{env}.tfvars`** - Environment-specific configurations
- **`config/passwords.txt`** - Generated secure passwords
- **`config/outputs.json`** - Deployment outputs

## 🏗️ Infrastructure Components

### Core Services

| Component | Purpose | SKU/Tier |
|-----------|---------|----------|
| **Resource Group** | Container for all resources | N/A |
| **Virtual Network** | Network isolation | Standard |
| **IoT Hub** | Device connectivity | S1 (1 unit) |
| **Event Hub** | Message streaming | Standard |
| **Service Bus** | Message queuing | Standard |
| **Storage Account** | Data storage | Standard LRS |
| **Cosmos DB** | NoSQL database | 400 RU |
| **SQL Database** | Relational database | S0 |
| **Function Apps** | Serverless compute | Consumption |
| **Container Apps** | Containerized services | Consumption |
| **API Management** | API gateway | Developer_1 |

### Security Services

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **Key Vault** | Secrets management | Standard |
| **Security Center** | Security monitoring | Enabled |
| **Log Analytics** | Centralized logging | Standard |
| **Application Insights** | Application monitoring | Standard |
| **DDoS Protection** | DDoS mitigation | Optional |

### Monitoring Services

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **Log Analytics Workspace** | Centralized logs | Standard |
| **Application Insights** | APM monitoring | Standard |
| **Action Groups** | Alert notifications | Email/SMS |
| **Alert Rules** | Automated alerting | Custom rules |

## 📊 Cost Optimization

### Estimated Monthly Costs

| Environment | Estimated Cost | Notes |
|-------------|----------------|-------|
| **Development** | $95-150 | Basic monitoring, minimal resources |
| **Staging** | $200-350 | Production-like setup |
| **Production** | $400-800 | Full monitoring, high availability |

### Cost Optimization Tips

1. **Use appropriate SKUs**
   - Development: F1 IoT Hub, Basic SQL DB
   - Production: S1+ IoT Hub, Standard+ SQL DB

2. **Enable auto-scaling**
   - Function Apps: Consumption plan
   - Container Apps: Consumption environment

3. **Configure retention policies**
   - Log retention: 30 days (dev), 90 days (prod)
   - Backup retention: 7 days (dev), 30 days (prod)

4. **Use reserved instances** (for production)
   - SQL Database: 1-year reserved
   - Storage: Cool/Archive tiers for old data

## 🔒 Security Configuration

### Network Security

- **Private Endpoints**: Enabled for all services
- **Network Security Groups**: Restrictive rules
- **VNet Integration**: All services in private subnets
- **DDoS Protection**: Optional (additional cost)

### Data Security

- **Encryption at Rest**: AES-256 for all services
- **Encryption in Transit**: TLS 1.3 for all communications
- **Key Management**: Azure Key Vault
- **Access Control**: RBAC with least privilege

### Compliance

- **GDPR**: Data anonymization, right to be forgotten
- **SOC 2**: Security controls and monitoring
- **ISO 27001**: Information security management

## 🚨 Troubleshooting

### Common Issues

1. **Permission Errors**
   ```bash
   # Check Azure permissions
   az account show
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

2. **Resource Conflicts**
   ```bash
   # Check for existing resources
   az group list --query "[?contains(name, 'iot-sound-analytics')]"
   ```

3. **Terraform State Issues**
   ```bash
   # Clean and reinitialize
   ./deploy-azure.sh plan --clean
   ```

4. **Configuration Validation**
   ```bash
   # Validate configuration
   ./config-manager.sh validate config/terraform-dev.tfvars
   ```

### Logs and Debugging

- **Deployment logs**: `logs/deployment-*.log`
- **Terraform logs**: Enable with `TF_LOG=DEBUG`
- **Azure logs**: Check Activity Log in Azure Portal

### Recovery Procedures

1. **Backup before changes**
   ```bash
   ./config-manager.sh backup dev
   ```

2. **Rollback deployment**
   ```bash
   # Restore from backup
   ./config-manager.sh restore config/backup-dev-*.tfvars
   
   # Redeploy
   ./deploy-azure.sh deploy
   ```

3. **Destroy and recreate**
   ```bash
   # Destroy resources
   ./deploy-azure.sh destroy
   
   # Recreate
   ./deploy-azure.sh deploy
   ```

## 📚 Advanced Usage

### Custom Modules

The deployment uses modular Terraform configuration:

```
modules/
├── networking/     # VNet, subnets, NSGs
├── iot_services/   # IoT Hub, Event Hub, Service Bus
├── compute/        # Function Apps, Container Apps
├── storage/        # Storage Account, Cosmos DB, SQL DB
├── security/       # Key Vault, Security Center
├── monitoring/     # Log Analytics, Application Insights
├── analytics/      # Power BI, Synapse (optional)
└── api/           # API Management, API Gateway
```

### Customization

1. **Add new resources**
   - Create new module in `modules/`
   - Add module call in `main.tf`
   - Update variables in `variables.tf`

2. **Modify existing resources**
   - Edit module files in `modules/`
   - Update variables as needed
   - Test with `terraform plan`

3. **Environment-specific overrides**
   - Use `terraform.tfvars` for values
   - Use `locals` for computed values
   - Use `data sources` for dynamic values

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
name: Deploy Azure Infrastructure
on:
  push:
    branches: [main]
    paths: ['Azure/terraform/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Deploy Infrastructure
        run: |
          cd Azure/terraform
          ./deploy-azure.sh deploy
```

## 📞 Support

### Getting Help

1. **Check logs**: `logs/deployment-*.log`
2. **Validate configuration**: `./config-manager.sh validate`
3. **Check Azure status**: `az account show`
4. **Review Terraform state**: `terraform show`

### Documentation

- **Azure Documentation**: https://docs.microsoft.com/azure/
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/
- **Project README**: ../README.md

### Contact

- **Issues**: Create GitHub issue
- **Documentation**: Update this file
- **Contributions**: Submit pull request

---

## 🎯 Next Steps

After successful deployment:

1. **Configure IoT devices** to connect to IoT Hub
2. **Deploy application code** to Function Apps
3. **Setup monitoring dashboards** in Azure Portal
4. **Configure alerting rules** for critical events
5. **Test end-to-end functionality** with sample data
6. **Setup CI/CD pipeline** for automated deployments

Happy deploying! 🚀
