terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------
# 1. IAM Role for EC2 (CloudWatch Agent)
# ---------------------------------------------
resource "aws_iam_role" "cw_role" {
  name = "cw_agent_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cw_policy" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.cw_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cw_profile" {
  name = "cw_agent_instance_profile"
  role = aws_iam_role.cw_role.name
}

# ---------------------------------------------
# 2. Security Group
# ---------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name   = "monitoring_ec2_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------
# 3. CloudWatch Log Groups
# ---------------------------------------------
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/application/error-logs"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "sys_metrics" {
  name              = "/system/metrics"
  retention_in_days = 30
}

# ---------------------------------------------
# 4. SNS Topic for Alerts
# ---------------------------------------------
resource "aws_sns_topic" "error_alerts" {
  name = "critical-error-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.error_alerts.arn
  protocol  = "email"
  endpoint  = var.user_email
}

# ---------------------------------------------
# 5. Lambda Role
# ---------------------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_cloudwatch_forwarder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "sns_publish" {
  name = "lambda_sns_publish_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = aws_sns_topic.error_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

# ---------------------------------------------
# 6. Lambda Function
# ---------------------------------------------
resource "aws_lambda_function" "log_filter_lambda" {
  function_name = "process-critical-logs"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"
  runtime       = "python3.12"

  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.error_alerts.arn
    }
  }
}

# ---------------------------------------------
# 7. Allow CloudWatch Logs to Invoke Lambda (FIX)
# ---------------------------------------------
resource "aws_lambda_permission" "cw_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_filter_lambda.function_name
  principal     = "logs.amazonaws.com"

  source_arn = "${aws_cloudwatch_log_group.app_logs.arn}:*"
}

# ---------------------------------------------
# 8. Subscription Filter
# ---------------------------------------------
resource "aws_cloudwatch_log_subscription_filter" "error_filter" {
  name            = "error-filter"
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  destination_arn = aws_lambda_function.log_filter_lambda.arn
  filter_pattern  = "{ $.level = \"ERROR\" || $.level = \"CRITICAL\" || $.level = \"FAILED\" }"

  depends_on = [
    aws_lambda_permission.cw_invoke
  ]
}

# ---------------------------------------------
# 9. EC2 Instance
# ---------------------------------------------
resource "aws_instance" "monitor_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.cw_profile.name

  user_data = file("user-data.sh")

  tags = {
    Name = "Monitoring-EC2"
  }
}
