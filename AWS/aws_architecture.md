# AWS realization (service mapping)
• Ingress: AWS IoT Core / MSK or Kinesis; VPC endpoints + IAM.
• Processing: AWS Lambda (Provisioned Concurrency when needed); AWS Fargate for feature extraction; SageMaker for model registry/training.
• Storage: S3 (Standard/IA/Glacier), DynamoDB for metadata/queries.
• Analytics & Alerts: Kinesis Data Analytics; EventBridge + Step Functions; SNS/SQS for notifications.
• North-bound: API Gateway; CloudFront.
• Security: KMS, Secrets Manager, PrivateLink, WAF, GuardDuty.

# service mapping diagram
![image](https://github.com/aliaksei-babuk/iot-sa-project/blob/main/AWS/deploy_aws.png)


# References:
https://aws.amazon.com/blogs/architecture/building-event-driven-architectures-with-iot-sensor-data/
https://aws.amazon.com/blogs/machine-learning/detect-audio-events-with-amazon-rekognition/