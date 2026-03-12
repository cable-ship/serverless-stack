variable "api_name" {
  description = "Name of the HTTP API Gateway."
  type        = string
}

variable "protocol_type" {
  description = "API protocol type (HTTP or WEBSOCKET)."
  type        = string
  default     = "HTTP"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "managed_by_tag" {
  description = "Value for ManagedBy tag."
  type        = string
  default     = "terraform"
}

variable "default_tags" {
  description = "Default tags merged before var.tags. Overrides Environment/ManagedBy when set."
  type        = map(string)
  default     = null
}

variable "stage_name" {
  description = "Name of the API stage."
  type        = string
  default     = "$default"
}

variable "stage_auto_deploy" {
  description = "Enable auto-deploy for the stage."
  type        = bool
  default     = true
}

variable "authorization_type" {
  description = "Authorization type for routes: NONE, AWS_IAM, JWT, or CUSTOM."
  type        = string
  default     = "JWT"
}

variable "cognito_client_id" {
  description = "Cognito User Pool Client ID (required when authorization_type is JWT)."
  type        = string
  default     = null
}

variable "cognito_issuer" {
  description = "Cognito User Pool issuer URL (required when authorization_type is JWT)."
  type        = string
  default     = null
}

variable "authorizer_id" {
  description = "Authorizer ID for CUSTOM authorization (required when authorization_type is CUSTOM)."
  type        = string
  default     = null
}

variable "authorizer_name" {
  description = "Name of the JWT authorizer."
  type        = string
  default     = "cognito-authorizer"
}

variable "authorizer_identity_sources" {
  description = "Identity sources for the authorizer."
  type        = list(string)
  default     = ["$request.header.Authorization"]
}

variable "routes" {
  description = "Map of routes with route_key, lambda_invoke_arn, lambda_function_name, and optional permission_statement_id."
  type = map(object({
    route_key               = string
    route_path              = optional(string)
    lambda_invoke_arn       = string
    lambda_function_name    = string
    permission_statement_id = optional(string)
  }))
}

variable "primary_route_key" {
  description = "Key in var.routes to use for api_primary_url output."
  type        = string
  default     = null
}

variable "integration_type" {
  description = "Integration type (AWS_PROXY, HTTP, etc.)."
  type        = string
  default     = "AWS_PROXY"
}

variable "integration_method" {
  description = "Integration HTTP method."
  type        = string
  default     = "POST"
}


variable "lambda_permission_statement_id" {
  description = "Statement ID for Lambda invoke permission."
  type        = string
  default     = "AllowAPIGatewayInvoke"
}

variable "lambda_permission_action" {
  description = "IAM action for Lambda invoke permission."
  type        = string
  default     = "lambda:InvokeFunction"
}

variable "lambda_permission_principal" {
  description = "Principal for Lambda invoke permission."
  type        = string
  default     = "apigateway.amazonaws.com"
}

variable "tags" {
  description = "Additional tags to merge onto API Gateway resources."
  type        = map(string)
  default     = {}
}
