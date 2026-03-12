output "api_id" {
  description = "ID of the HTTP API Gateway."
  value       = aws_apigatewayv2_api.this.id
}

output "api_url" {
  description = "Base invoke URL of the API Gateway default stage."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

locals {
  primary_route_path = var.primary_route_key != null && contains(keys(var.routes), var.primary_route_key) ? coalesce(var.routes[var.primary_route_key].route_path, trimprefix(trimspace(trimprefix(var.routes[var.primary_route_key].route_key, "GET ")), "/")) : null
}

output "api_primary_url" {
  description = "Full URL for the primary route (when primary_route_key is set in var.routes)."
  value       = local.primary_route_path != null ? "${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}/${local.primary_route_path}" : null
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway (used for Lambda permissions)."
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "authorizer_id" {
  description = "ID of the JWT authorizer (null when authorization_type is not JWT)."
  value       = var.authorization_type == "JWT" ? aws_apigatewayv2_authorizer.jwt[0].id : null
}
