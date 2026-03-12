variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "hash_key" {
  description = "Attribute name to use as the hash (partition) key."
  type        = string
  default     = "request_id"
}

variable "hash_key_type" {
  description = "Data type of the hash key: S (string), N (number), B (binary)."
  type        = string
  default     = "S"
}

variable "range_key" {
  description = "Attribute name for the range (sort) key. Set to null for hash-key-only table."
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Data type of the range key: S, N, B. Used when range_key is set."
  type        = string
  default     = "S"
}

variable "billing_mode" {
  description = "Billing mode: PAY_PER_REQUEST or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Read capacity units (required when billing_mode is PROVISIONED)."
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "Write capacity units (required when billing_mode is PROVISIONED)."
  type        = number
  default     = null
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery."
  type        = bool
  default     = false
}

variable "server_side_encryption_enabled" {
  description = "Enable server-side encryption (SSE) at rest."
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
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
  description = "Default tags merged before var.tags. When null, uses Environment and ManagedBy."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Additional tags to merge onto the table."
  type        = map(string)
  default     = {}
}
