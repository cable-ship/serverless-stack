variable "roles" {
  description = "Map of IAM roles to create. Key used for resource naming."
  type = map(object({
    name                 = string
    path                 = optional(string, "/")
    description          = optional(string)
    assume_role_policy   = string # JSON string
    permissions_boundary = optional(string)
    max_session_duration = optional(number)
    inline_policies      = optional(map(string), {})  # policy_name -> policy JSON
    managed_policy_arns  = optional(list(string), []) # AWS or customer managed policy ARNs
  }))
  default = {}
}

variable "environment" {
  description = "Environment name for tagging."
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
  description = "Additional tags to merge onto all resources."
  type        = map(string)
  default     = {}
}
