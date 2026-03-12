output "role_arn" {
  description = "Map of role key -> ARN."
  value       = { for k, r in aws_iam_role.this : k => r.arn }
}

output "role_name" {
  description = "Map of role key -> name."
  value       = { for k, r in aws_iam_role.this : k => r.name }
}

output "role_id" {
  description = "Map of role key -> ID."
  value       = { for k, r in aws_iam_role.this : k => r.id }
}
