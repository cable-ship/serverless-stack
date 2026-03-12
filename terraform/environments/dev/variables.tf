########################################################################
# General
########################################################################

variable "project_name" {
  description = "Project name used in resource naming (e.g. unleash, myapp)."
  type        = string
  default     = "unleash"
}

variable "environment" {
  description = "Environment name used in resource naming and tags."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region for this deployment (one region per terraform apply)."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "azs" {
  description = "Availability zones for the region."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

########################################################################
# Application
########################################################################

variable "cognito_user_email" {
  description = "Email address for the Cognito test user."
  type        = string
}

variable "notification_email" {
  description = "Email address for SNS notifications and event messages."
  type        = string
}

variable "external_sns_topic_arn" {
  description = "ARN of external SNS topic (if using cross-account SNS). Leave empty to create new topic."
  type        = string
  default     = ""
}

variable "enable_email_notifications" {
  description = "Enable email notifications via SNS subscription."
  type        = bool
  default     = false
}

variable "repo_url" {
  description = "Repository URL embedded in the SNS notification payload."
  type        = string
}

########################################################################
# Naming (optional overrides)
########################################################################

variable "sns_topic_name_prefix" {
  description = "SNS topic name prefix. Final name is {prefix}-{region}."
  type        = string
  default     = "greeter-verification"
}

variable "dynamodb_table_name_prefix" {
  description = "DynamoDB table name prefix. Final name is {prefix}-{region}."
  type        = string
  default     = "greeting-logs"
}

########################################################################
# Cognito (optional overrides)
########################################################################

variable "cognito_user_pool_name" {
  description = "Cognito User Pool name. Defaults to {environment}-user-pool."
  type        = string
  default     = null
}

variable "cognito_user_pool_client_name" {
  description = "Cognito User Pool Client name. Defaults to {environment}-user-pool-client."
  type        = string
  default     = null
}

variable "cognito_password_minimum_length" {
  description = "Cognito minimum password length."
  type        = number
  default     = 8
}

variable "cognito_test_user_temporary_password" {
  description = "Temporary password for Cognito test user (change on first sign-in)."
  type        = string
  default     = "TempPass1!"
  sensitive   = true
}

variable "cognito_test_user_set_permanent_password" {
  description = "If true, Terraform sets the test user's password as permanent (skips NEW_PASSWORD_REQUIRED). If false, user must set a new password on first sign-in."
  type        = bool
  default     = true
}

variable "cognito_create_test_user" {
  description = "Create Cognito test user (set false if managing users elsewhere)."
  type        = bool
  default     = true
}

########################################################################
# DynamoDB (optional overrides)
########################################################################

variable "dynamodb_hash_key" {
  description = "DynamoDB partition key attribute name."
  type        = string
  default     = "request_id"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PAY_PER_REQUEST or PROVISIONED."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable DynamoDB point-in-time recovery."
  type        = bool
  default     = false
}

variable "dynamodb_server_side_encryption" {
  description = "Enable DynamoDB server-side encryption at rest."
  type        = bool
  default     = true
}

########################################################################
# ECS (optional overrides)
########################################################################

variable "ecs_task_cpu" {
  description = "ECS Fargate task CPU units (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "ECS Fargate task memory in MB (512, 1024, 2048, 4096, 8192)."
  type        = number
  default     = 512
}

variable "ecs_log_retention_in_days" {
  description = "CloudWatch Log Group retention for ECS tasks."
  type        = number
  default     = 7
}

variable "ecs_container_image" {
  description = "Container image for the ECS event-processor task."
  type        = string
  default     = "public.ecr.aws/aws-cli/aws-cli:latest"
}

########################################################################
# IAM (optional overrides)
########################################################################

variable "iam_path" {
  description = "IAM path for Lambda/ECS roles."
  type        = string
  default     = "/"
}

variable "iam_permissions_boundary" {
  description = "ARN of permissions boundary for IAM roles (e.g. enterprise policy)."
  type        = string
  default     = null
}

variable "iam_trust_policy" {
  description = "Custom assume role policy JSON for Lambda roles. Defaults to lambda.amazonaws.com trust."
  type        = string
  default     = null
}

variable "iam_greeter_policy_file" {
  description = "Path to greeter policy template (relative to dev env). Placeholder: sns_topic_arn."
  type        = string
  default     = "policies/greeter-policy.json.tpl"
}

variable "iam_dispatcher_policy_file" {
  description = "Path to dispatcher policy template. Placeholders: table_arn."
  type        = string
  default     = "policies/dispatcher-policy.json.tpl"
}

########################################################################
# Lambda
########################################################################

variable "lambda_runtime" {
  description = "Lambda function runtime."
  type        = string
  default     = "python3.12"
}

########################################################################
# Networking — us-east-1
########################################################################

variable "use1_vpc_cidr" {
  description = "VPC CIDR block for us-east-1."
  type        = string
  default     = "10.0.0.0/16"
}

variable "use1_azs" {
  description = "Availability zones for us-east-1."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "use1_public_subnets" {
  description = "Public subnet CIDRs for us-east-1."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

########################################################################
# Networking — eu-west-1
########################################################################

variable "euw1_vpc_cidr" {
  description = "VPC CIDR block for eu-west-1."
  type        = string
  default     = "10.1.0.0/16"
}

variable "euw1_azs" {
  description = "Availability zones for eu-west-1."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "euw1_public_subnets" {
  description = "Public subnet CIDRs for eu-west-1."
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

########################################################################
# Tags
########################################################################

variable "tags" {
  description = "Extra tags to merge with common tags (Environment, ManagedBy, Project)."
  type        = map(string)
  default     = {}
}
