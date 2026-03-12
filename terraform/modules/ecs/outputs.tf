output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "log_group_name" {
  description = "Name of the ECS CloudWatch log group."
  value       = aws_cloudwatch_log_group.ecs.name
}

output "security_group_id" {
  description = "ID of the ECS task security group."
  value       = aws_security_group.ecs_task.id
}

output "container_name" {
  description = "Primary container name (for run_task overrides)."
  value       = var.container_name
}
