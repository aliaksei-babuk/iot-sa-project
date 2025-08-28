# aws/main.tf
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws     = { source = "hashicorp/aws",     version = "~> 5.0" }
    random  = { source = "hashicorp/random",  version = "~> 3.6" }
    archive = { source = "hashicorp/archive", version = "~> 2.5" }
  }
}

provider "aws" { region = var.region }

variable "prefix" { type = string, default = "iot-sa" }
variable "region" { type = string, default = "eu-west-1" }

resource "random_string" "suffix" { length = 5, upper = false, special = false }
locals { name = "${var.prefix}-${random_string.suffix.result}" }

data "aws_availability_zones" "azs" {}

# ---------- VPC (simplified public subnets for demo) ----------
resource "aws_vpc" "vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${local.name}-vpc" }
}
resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.vpc.id }
resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
}
resource "aws_subnet" "pub_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true
}
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route { cidr_block = "0.0.0.0/0"  gateway_id = aws_internet_gateway.igw.id }
}
resource "aws_route_table_association" "a" { subnet_id = aws_subnet.pub_a.id  route_table_id = aws_route_table.rt.id }
resource "aws_route_table_association" "b" { subnet_id = aws_subnet.pub_b.id  route_table_id = aws_route_table.rt.id }

# ---------- Kinesis (ingress) ----------
resource "aws_kinesis_stream" "telemetry" {
  name = "${local.name}-telemetry"
  shard_count = 1
  retention_period = 24
  stream_mode_details { stream_mode = "PROVISIONED" }
}

# ---------- Data lake & metadata ----------
resource "aws_s3_bucket" "data" {
  bucket        = "${local.name}-data"
  force_destroy = true
}
resource "aws_dynamodb_table" "metadata" {
  name         = "${local.name}-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  attribute { name = "pk" type = "S" }
}

# ---------- Lambda (ingestion/validation) ----------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}-ingestion"
  retention_in_days = 14
}
resource "aws_iam_role" "lambda_exec" {
  name = "${local.name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect="Allow", Principal={ Service="lambda.amazonaws.com" }, Action="sts:AssumeRole" }]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_stub.zip"
  source { filename = "index.js" content = "exports.handler=async()=>({statusCode:200,body:'ok'});" }
}
resource "aws_lambda_function" "ingestion" {
  function_name = "${local.name}-ingestion"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = data.archive_file.zip.output_path
  timeout       = 10
  environment {
    variables = {
      KINESIS_STREAM = aws_kinesis_stream.telemetry.name
      DDB_TABLE      = aws_dynamodb_table.metadata.name
      S3_BUCKET      = aws_s3_bucket.data.bucket
    }
  }
  depends_on = [aws_cloudwatch_log_group.lambda]
}
resource "aws_lambda_event_source_mapping" "kinesis_to_lambda" {
  event_source_arn  = aws_kinesis_stream.telemetry.arn
  function_name     = aws_lambda_function.ingestion.arn
  starting_position = "LATEST"
  batch_size        = 100
  enabled           = true
}

# ---------- ECS/Fargate (feature extraction placeholder) ----------
resource "aws_ecs_cluster" "ecs" { name = "${local.name}-ecs" }
resource "aws_iam_role" "ecs_task" {
  name = "${local.name}-ecs-task"
  assume_role_policy = jsonencode({
    Version="2012-10-17",
    Statement=[{Effect="Allow",Principal={Service="ecs-tasks.amazonaws.com"},Action="sts:AssumeRole"}]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_exec" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_security_group" "ecs_sg" {
  name   = "${local.name}-ecs-sg"
  vpc_id = aws_vpc.vpc.id
  ingress { from_port=80 to_port=80 protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  egress  { from_port=0  to_port=0  protocol="-1"  cidr_blocks=["0.0.0.0/0"] }
}
resource "aws_ecs_task_definition" "fe" {
  family                   = "${local.name}-fe"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task.arn
  container_definitions    = jsonencode([{
    name="fe", image="public.ecr.aws/docker/library/nginx:latest", essential=true,
    portMappings=[{containerPort:80,hostPort:80}],
    environment=[{name="KINESIS_STREAM", value=aws_kinesis_stream.telemetry.name}]
  }])
  runtime_platform { operating_system_family = "LINUX"  cpu_architecture = "X86_64" }
}
resource "aws_ecs_service" "fe" {
  name            = "${local.name}-fe"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.fe.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.pub_a.id, aws_subnet.pub_b.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

# ---------- API Gateway (north-bound) ----------
resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
}
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingestion.invoke_arn
  payload_format_version = "2.0"
}
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /status"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# ---------- Outputs ----------
output "api_endpoint"   { value = aws_apigatewayv2_api.http.api_endpoint }
output "kinesis_stream" { value = aws_kinesis_stream.telemetry.name }
output "lambda_name"    { value = aws_lambda_function.ingestion.function_name }
output "ecs_service"    { value = aws_ecs_service.fe.name }
output "s3_bucket"      { value = aws_s3_bucket.data.bucket }
output "dynamodb_table" { value = aws_dynamodb_table.metadata.name }
