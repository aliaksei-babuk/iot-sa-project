# AWS IoT Sound Analytics - Terraform Infrastructure

This directory contains the Terraform configuration for deploying the AWS IoT Sound Analytics platform. The infrastructure is organized into modules for better maintainability and reusability.

## Architecture Overview

The infrastructure implements a serverless architecture for real-time sound analytics in IoT environments, featuring:

- **Event-driven processing** with AWS Lambda and Kinesis
- **Multi-tier storage** with DynamoDB, RDS, S3, and ElastiCache
- **Machine learning** capabilities with SageMaker
- **Real-time analytics** with Kinesis Analytics and QuickSight
- **API Gateway** for unified access
- **Comprehensive monitoring** with CloudWatch and X-Ray
- **Security** with IAM, KMS, WAF, and Security Hub

## Module Structure

```
terraform/
├── main.tf                    # Main configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── README.md                  # This file
└── modules/
    ├── networking/            # VPC, subnets, security groups
    ├── security/              # IAM, KMS, WAF, Security Hub
    ├── iot_services/          # IoT Core, Kinesis, SQS
    ├── storage/               # DynamoDB, RDS, S3, ElastiCache
    ├── compute/               # Lambda, Fargate, Step Functions
    ├── analytics/             # SageMaker, QuickSight, Kinesis Analytics
    ├── api/                   # API Gateway, CloudFront, ALB
    └── monitoring/            # CloudWatch, X-Ray, SNS
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **AWS Account** with sufficient permissions
4. **Domain name** for SSL certificates (optional)

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd iot-sa-project/AWS/terraform
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

6. **View outputs**
   ```bash
   terraform output
   ```

## Configuration

### Required Variables

- `project_name`: Name of the project
- `environment`: Environment (dev/staging/prod)
- `aws_region`: AWS region for deployment
- `owner`: Owner of the resources

### Optional Variables

All other variables have sensible defaults. See `terraform.tfvars.example` for a complete list.

## Module Details

### Networking Module
- VPC with public, private, and database subnets
- Internet Gateway and NAT Gateways
- Security groups for different tiers
- VPC endpoints for AWS services

### Security Module
- KMS key for encryption
- IAM roles and policies
- WAF Web ACL
- Security Hub and GuardDuty

### IoT Services Module
- IoT Core for device connectivity
- Kinesis Data Streams for event processing
- SQS queues for message handling
- IoT rules for data routing

### Storage Module
- DynamoDB for real-time data
- RDS PostgreSQL for structured data
- S3 for object storage with lifecycle policies
- ElastiCache Redis for caching

### Compute Module
- Lambda functions for serverless processing
- Fargate for containerized workloads
- Step Functions for workflow orchestration

### Analytics Module
- SageMaker for ML model training and inference
- Kinesis Analytics for real-time processing
- QuickSight for dashboards and visualization

### API Module
- API Gateway for RESTful APIs
- CloudFront for global distribution
- Application Load Balancer for load balancing

### Monitoring Module
- CloudWatch for metrics and logs
- X-Ray for distributed tracing
- SNS for alerting

## Cost Optimization

The configuration includes several cost optimization features:

- **S3 Lifecycle Policies**: Automatic transition to cheaper storage tiers
- **DynamoDB On-Demand**: Pay-per-request billing
- **Lambda**: Pay-per-execution model
- **Fargate Spot**: Use spot instances for non-critical workloads
- **CloudWatch Log Retention**: Configurable log retention periods

## Security Features

- **Encryption**: All data encrypted at rest and in transit
- **Network Isolation**: Private subnets for sensitive resources
- **Access Control**: IAM roles with least privilege
- **Monitoring**: Security Hub and GuardDuty for threat detection
- **WAF**: Web Application Firewall for API protection

## Monitoring and Observability

- **CloudWatch Dashboards**: Real-time system metrics
- **X-Ray Tracing**: Distributed request tracing
- **SNS Alerts**: Proactive notification system
- **Log Aggregation**: Centralized logging across all services

## Disaster Recovery

- **Multi-AZ Deployment**: High availability across availability zones
- **Automated Backups**: RDS automated backups
- **Cross-Region Replication**: S3 cross-region replication (optional)

## Scaling

The infrastructure is designed to scale automatically:

- **Lambda**: Auto-scaling based on demand
- **Fargate**: Auto-scaling based on CPU/memory utilization
- **DynamoDB**: On-demand scaling
- **Kinesis**: Configurable shard count

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure AWS credentials have sufficient permissions
2. **Resource Limits**: Check AWS service limits in your account
3. **VPC Limits**: Ensure you have enough VPC resources available
4. **Domain Validation**: SSL certificate validation may require DNS configuration

### Useful Commands

```bash
# View current state
terraform show

# List resources
terraform state list

# Import existing resources
terraform import <resource_type>.<name> <resource_id>

# Destroy infrastructure
terraform destroy
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources. Make sure to backup any important data first.

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review AWS documentation for specific services
3. Check Terraform documentation for syntax issues
4. Open an issue in the repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.
