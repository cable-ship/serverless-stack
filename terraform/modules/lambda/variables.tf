variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "role_arn" {
  description = "ARN of the IAM role for the Lambda (required when create_role is false)."
  type        = string
  default     = null
}

variable "create_role" {
  description = "Create an IAM role for the Lambda via the embedded IAM module; use role_config. When true, role_arn is ignored."
  type        = bool
  default     = false
}

variable "role_config" {
  description = "When create_role is true: name, path, assume_role_policy (e.g. Lambda trust policy), inline_policies (map of policy name -> JSON)."
  type = object({
    name                 = string
    path                 = optional(string, "/")
    assume_role_policy   = string
    inline_policies      = optional(map(string), {})
    permissions_boundary = optional(string)
  })
  default = null
}

variable "handler" {
  description = "Lambda handler in the format file.function (e.g. app.handler)."
  type        = string
  default     = "app.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "filename" {
  description = "Path to the deployment zip package."
  type        = string
}

variable "environment_variables" {
  description = "Map of environment variables to pass to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Amount of memory in MB allocated to the Lambda function."
  type        = number
  default     = 256
}

variable "environment" {
  description = "Environment name used for tagging."
  type        = string
}

variable "managed_by_tag" {
  description = "Value for ManagedBy tag."
  type        = string
  default     = "terraform"
}

variable "default_tags" {
  description = "Default tags merged before var.tags. When null, uses Environment and ManagedBy."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Additional tags to merge onto the function."
  type        = map(string)
  default     = {}
}

variable "invocation_permissions" {
  description = "List of permissions allowing other services to invoke this Lambda (e.g. API Gateway, SNS, EventBridge). Each: statement_id, principal, source_arn."
  type = list(object({
    statement_id = string
    principal    = string
    source_arn   = string
  }))
  default = []
}

variable "event_invoke_config" {
  description = "Optional async invocation config: destination_on_success_arn, destination_on_failure_arn (SQS/SNS/Lambda/EventBridge), maximum_retry_attempts, maximum_event_age_in_seconds."
  type = object({
    destination_on_success_arn   = optional(string)
    destination_on_failure_arn   = optional(string)
    maximum_retry_attempts       = optional(number)
    maximum_event_age_in_seconds = optional(number)
  })
  default = null
}
