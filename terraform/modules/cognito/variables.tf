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
  description = "Default tags merged before var.tags. When null, uses Environment and ManagedBy."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to Cognito resources."
  type        = map(string)
  default     = {}
}

variable "pools" {
  description = "Map of User Pools. Each pool can have multiple clients and users."
  type = map(object({
    name = optional(string) # defaults to {pool_key} or {environment}-{pool_key}

    # Password policy (optional overrides)
    password_minimum_length          = optional(number, 8)
    password_require_uppercase       = optional(bool, true)
    password_require_lowercase       = optional(bool, true)
    password_require_numbers         = optional(bool, true)
    password_require_symbols         = optional(bool, false)
    temporary_password_validity_days = optional(number, 7)

    auto_verified_attributes = optional(list(string), ["email"])

    # Schema attributes (default: email). Add custom attributes with "custom:name".
    schema_attributes = optional(list(object({
      name                = string
      attribute_data_type = optional(string, "String")
      required            = optional(bool, true)
      mutable             = optional(bool, true)
    })), [{ name = "email", attribute_data_type = "String", required = true, mutable = true }])

    # App clients: map of client_key -> client config
    clients = optional(map(object({
      name                                 = optional(string)
      generate_secret                      = optional(bool, false)
      explicit_auth_flows                  = optional(list(string), ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"])
      prevent_user_existence_errors        = optional(string, "ENABLED")
      enable_token_revocation              = optional(bool, true)
      allowed_oauth_flows_user_pool_client = optional(bool, false)
    })), {})

    # Users: map of user_key -> user config
    users = optional(map(object({
      username               = string # email for email-based auth
      temporary_password     = optional(string, "TempPass1!")
      message_action         = optional(string, "SUPPRESS")
      email_verified         = optional(bool, true)
      set_permanent_password = optional(bool, true) # run admin-set-user-password so USER_PASSWORD_AUTH works
    })), {})
  }))
  default = {}
}
