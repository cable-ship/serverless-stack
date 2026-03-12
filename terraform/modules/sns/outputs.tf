output "topic_arn" {
  description = "ARN of the SNS topic (created or existing)."
  value       = local.topic_arn
}

output "topic_name" {
  description = "Name of the SNS topic (only available when create_topic is true)."
  value       = var.create_topic ? aws_sns_topic.this[0].name : null
}
