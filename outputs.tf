output "cloudwatch_log_groups" {
  description = "Created CloudWatch Log Groups"
  value = [
    aws_cloudwatch_log_group.app_logs.name,
    aws_cloudwatch_log_group.sys_metrics.name
  ]
}

output "sns_topic_arn" {
  description = "SNS Topic for Error Alerts"
  value       = aws_sns_topic.error_alerts.arn
}

output "lambda_function_name" {
  description = "Lambda Function"
  value       = aws_lambda_function.log_filter_lambda.function_name
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.monitor_ec2.id
}