output "user_pool_ids" {
  description = "Map of pool_key -> User Pool ID."
  value       = { for k, p in aws_cognito_user_pool.this : k => p.id }
}

output "user_pool_arns" {
  description = "Map of pool_key -> User Pool ARN."
  value       = { for k, p in aws_cognito_user_pool.this : k => p.arn }
}

output "user_pool_endpoints" {
  description = "Map of pool_key -> User Pool endpoint."
  value       = { for k, p in aws_cognito_user_pool.this : k => p.endpoint }
}

output "client_ids" {
  description = "Map of \"pool_key.client_key\" -> User Pool Client ID."
  value       = { for k, c in aws_cognito_user_pool_client.this : k => c.id }
}

output "issuer_urls" {
  description = "Map of pool_key -> JWT issuer URL (for authorizer)."
  value       = { for k, p in aws_cognito_user_pool.this : k => "https://${p.endpoint}" }
}

# Convenience: single pool/client (when only one pool and one client exist)
output "user_pool_id" {
  description = "Single pool ID (first pool). Use user_pool_ids for multi-pool."
  value       = length(aws_cognito_user_pool.this) == 1 ? values(aws_cognito_user_pool.this)[0].id : null
}

output "user_pool_client_id" {
  description = "Single client ID (first pool's first client). Use client_ids for multi-pool."
  value       = length(aws_cognito_user_pool_client.this) == 1 ? values(aws_cognito_user_pool_client.this)[0].id : null
}

output "issuer_url" {
  description = "Single issuer URL (first pool). Use issuer_urls for multi-pool."
  value       = length(aws_cognito_user_pool.this) == 1 ? "https://${values(aws_cognito_user_pool.this)[0].endpoint}" : null
}
