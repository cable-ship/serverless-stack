variable "region" {
  description = "AWS region (for naming defaults)."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name. When null, uses cluster_name_prefix-<region>."
  type        = string
  default     = null
}

variable "cluster_name_prefix" {
  description = "Prefix for default cluster name when cluster_name is null."
  type        = string
  default     = "ecs-cluster"
}

variable "task_definition_family" {
  description = "Task definition family. When null, uses ecs-task-<region>."
  type        = string
  default     = null
}

variable "task_cpu" {
  description = "CPU units for Fargate (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory in MB for Fargate (512, 1024, 2048, 4096, 8192)."
  type        = number
  default     = 512
}

# Caller provides roles (from IAM module or elsewhere)
variable "execution_role_arn" {
  description = "ARN of the IAM role for ECS task execution (pull image, logs)."
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the IAM role for the ECS task (container permissions)."
  type        = string
}

# Caller provides full container definitions (includes log config, env, image)
variable "container_definitions" {
  description = "Full container definitions JSON (array). Caller must provide; include logConfiguration, environment, etc."
  type        = string
}

# Support resources (log group + security group)
variable "vpc_id" {
  description = "VPC ID for the ECS task security group."
  type        = string
}

variable "ecs_log_retention_in_days" {
  description = "CloudWatch Logs retention (days) for ECS task log group."
  type        = number
  default     = 7
}

# Optional: for outputs used by run_task (e.g. Lambda dispatcher)
variable "container_name" {
  description = "Primary container name (for run_task overrides / outputs)."
  type        = string
  default     = "app"
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

variable "requires_compatibilities" {
  description = "ECS launch type (FARGATE or EC2)."
  type        = list(string)
  default     = ["FARGATE"]
}

variable "network_mode" {
  description = "Network mode for the task (awsvpc required for Fargate)."
  type        = string
  default     = "awsvpc"
}

variable "tags" {
  description = "Tags to apply to ECS resources."
  type        = map(string)
  default     = {}
}
