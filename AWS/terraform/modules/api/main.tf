# API Module - Main Configuration
# This module creates API Gateway, CloudFront, and ALB resources

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_gateway_name
  description = "API Gateway for ${var.project_name}-${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# API Gateway Resource
resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

# API Gateway Method
resource "aws_api_gateway_method" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_function_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [aws_api_gateway_integration.main]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.api_gateway_stage_name

  lifecycle {
    create_before_destroy = true
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = aws_api_gateway_rest_api.main.execution_arn
    origin_id   = "api-gateway"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "api-gateway"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = var.tags
}

# ALB Target Group
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = var.tags
}

# ALB Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ALB Listener for HTTPS
resource "aws_lb_listener" "main_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
}
