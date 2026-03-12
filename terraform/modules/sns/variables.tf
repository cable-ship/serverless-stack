variable "create_topic" {
  description = "Create a new SNS topic. Set to false to use an existing topic via existing_topic_arn."
  type        = bool
  default     = true

  validation {
    condition     = var.create_topic || var.existing_topic_arn != null
    error_message = "When create_topic is false, existing_topic_arn must be provided."
  }
}

variable "existing_topic_arn" {
  description = "ARN of an existing SNS topic to subscribe to. Required when create_topic is false."
  type        = string
  default     = null

  validation {
    condition     = var.existing_topic_arn == null || can(regex("^arn:aws:sns:[a-z0-9-]+:[0-9]+:.+$", var.existing_topic_arn))
    error_message = "existing_topic_arn must be a valid SNS topic ARN."
  }
}

variable "topic_name" {
  description = "Name of the SNS topic. Required when create_topic is true."
  type        = string
  default     = null

  validation {
    condition     = !var.create_topic || var.topic_name != null
    error_message = "topic_name is required when create_topic is true."
  }
}

variable "environment" {
  description = "Environment name for tagging."
  type        = string
}

variable "fifo_topic" {
  description = "Create a FIFO topic."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topic."
  type        = bool
  default     = false
}

variable "subscriptions" {
  description = "Map of subscriptions. Key is a unique id. Each value: protocol (email, email-json, lambda, sqs, https), endpoint, and lambda_function_name (required when protocol is lambda)."
  type = map(object({
    protocol             = string
    endpoint             = string
    lambda_function_name = optional(string)
  }))
  default = {}
}

variable "create_email_subscription" {
  description = "Create email subscription (legacy; use subscriptions map instead)."
  type        = bool
  default     = true
}

variable "email_subscription_protocol" {
  description = "Protocol for legacy email subscription."
  type        = string
  default     = "email"
}

variable "email_endpoint" {
  description = "Email for legacy subscription (when create_email_subscription is true)."
  type        = string
  default     = null
}

variable "managed_by_tag" {
  description = "Value for ManagedBy tag."
  type        = string
  default     = "terraform"
}

variable "default_tags" {
  description = "Default tags merged before var.tags."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Additional tags for the topic."
  type        = map(string)
  default     = {}
}
