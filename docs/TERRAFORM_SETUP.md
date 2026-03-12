# Terraform Setup — Multi-Region Serverless Stack

## 1. Prerequisites

- **AWS account** with permissions to create IAM, Lambda, API Gateway, SNS, DynamoDB, ECS, VPC, and S3 resources.
- **AWS CLI** configured with a profile that has the required permissions:
  - `aws configure` or environment variables (`AWS_ACCESS_KEY_ID`, etc.).
- **Terraform** `>= 1.7.5`.
- **Python** `3.12` (for building Lambda packages and running local scripts).
- CLI tools: `curl`, `jq`, `zip`.

## 2. Repository Layout (Terraform)

Relevant Terraform directories:

- `terraform/environments/dev/`
  - Environment-specific configuration (`main.tf`, `variables.tf`, etc.).
  - Region-specific variable files under `terraform/environments/dev/<region>/terraform.tfvars`.
- `terraform/modules/`
  - Reusable modules for networking, Cognito, Lambda, ECS, SNS, DynamoDB, API Gateway, IAM, etc.

## 3. Configure Variables

From the repo root:

```bash
cd terraform/environments/dev
```

Then:

- Optionally edit `terraform.tfvars` to set **shared defaults** such as:
  - `project_name`
  - `environment` (e.g., `"dev"`)
  - `lambda_runtime`
- For each region (e.g. `us-east-1`, `eu-west-1`), ensure there is a matching `terraform/environments/dev/<region>/terraform.tfvars` file with **region-specific values**, including:
  - `region`
  - `vpc_cidr`, `azs`, `public_subnets`
  - `user_email` (for SNS/email flows)
  - `repo_url` (repository URL used in notifications)

## 4. Build Lambda Packages

From the repo root:

```bash
cd services/greeter-lambda && zip -j greeter.zip app.py
cd ../dispatcher-lambda && zip -j dispatcher.zip app.py
```

These `.zip` files are referenced by the Lambda Terraform modules.

## 5. Initialize Terraform

From `terraform/environments/dev`:

```bash
terraform init
```

If you are using a remote backend (S3), you may instead run:

```bash
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=aws-assessment/dev/us-east-1.tfstate"
```

Adjust the `key` and `bucket` as needed for your environment.


## 6. Multi-Region Deployment

The stack is designed to be deployed into multiple regions using the same modules.

- Each region has its own `terraform/environments/dev/<region>/terraform.tfvars`.
- The CI pipeline runs `plan`/`apply` for each region independently (see [`CI_CD.md`](CI_CD.md) ).

To deploy manually to a second region (e.g. `eu-west-1`), repeat the **Plan and Apply** step using the region’s tfvars file:

```bash
terraform plan -var-file="eu-west-1/terraform.tfvars"
terraform apply
```

## 7. Cleaning Up

To destroy resources in a region:

```bash
terraform destroy -var-file="us-east-1/terraform.tfvars"
```

Repeat per region as needed.

## 8. Troubleshooting

- **Authentication issues**: Verify your AWS CLI profile and IAM permissions.
- **State backend errors**: Check that the S3 bucket exists and your IAM role can read/write it.
- **Module version drift**: Run `terraform init -upgrade` if modules or providers have changed.

---

## 9. Module Reference

All modules support `default_tags`, `managed_by_tag`, and `tags` for consistent tagging. Override defaults via variables when needed.

### 9.1 `modules/networking`

| Input | Description |
|---|---|
| `vpc_name` | Name tag for the VPC |
| `cidr` | VPC CIDR block |
| `azs` | List of availability zones |
| `public_subnets` | List of public subnet CIDRs |
| `region` | AWS region (for VPC endpoint service name) |
| `public_route_destination_cidr` | Default route CIDR (default `0.0.0.0/0`) |
| `eip_domain` | EIP domain for NAT (default `vpc`) |

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | List of public subnet IDs |

Creates a CloudWatch Logs interface VPC endpoint so ECS Fargate tasks can stream logs without internet access.

### 9.2 `modules/cognito`

| Input | Description |
|---|---|
| `environment` | Environment label |
| `pools` | Map of pool_key → pool config (name, password_*, clients, users, schema_attributes) |

Each pool can define `schema_attributes` (default: email), `clients` (map), and `users` (map). See `terraform/modules/cognito/README.md` for full structure.

| Output | Description |
|---|---|
| `user_pool_id` | Cognito User Pool ID (single pool) |
| `user_pool_client_id` | App Client ID (single pool) |
| `issuer_url` | JWT issuer URL for API Gateway authorizer |

### 9.3 `modules/iam` (roles only)

| Input | Description |
|---|---|
| `roles` | Map of role_key → config (name, path, assume_role_policy, inline_policies, managed_policy_arns) |
| `environment` | Environment label |

| Output | Description |
|---|---|
| `role_arn` | Map of role_key → role ARN |

### 9.4 `modules/lambda`

| Input | Description |
|---|---|
| `function_name` | Lambda function name |
| `role_arn` | Execution role ARN (or use `create_role` + `role_config`) |
| `handler` | Handler in `file.function` format |
| `runtime` | e.g. `python3.12` |
| `filename` | Path to the `.zip` deployment package |
| `environment_variables` | Map of env vars |
| `invocation_permissions` | Optional list of triggers (API Gateway, SNS, etc.) |

| Output | Description |
|---|---|
| `function_name` | Lambda function name |
| `function_arn` | Lambda ARN |
| `invoke_arn` | ARN for API Gateway integration |

### 9.5 `modules/ecs` (cluster + task definition only)

| Input | Description |
|---|---|
| `region` | Deploying region (for naming defaults) |
| `environment` | Environment label |
| `cluster_name` | ECS cluster name (optional) |
| `execution_role_arn` | IAM role for task execution (pull image, logs) |
| `task_role_arn` | IAM role for the task (container permissions) |
| `container_definitions` | Full container definitions JSON (caller provides) |
| `task_cpu`, `task_memory` | Fargate size |
| `requires_compatibilities` | Launch type (default `["FARGATE"]`) |
| `network_mode` | `awsvpc` (required for Fargate) |

Caller provides: IAM roles, security group, log group, and `container_definitions` JSON.

| Output | Description |
|---|---|
| `cluster_name` | ECS cluster name |
| `cluster_arn` | ECS cluster ARN |
| `task_definition_arn` | Task definition ARN |
| `container_name` | Primary container name (for `run_task`) |

### 9.6 `modules/sns`

> **🔔 Key Feature**: This module can both create new SNS topics AND subscribe to existing external topics (including cross-account scenarios). This allows your Lambda functions to react to events from topics managed outside your stack.

| Input | Description |
|---|---|
| `create_topic` | Create new topic (default true); set false to use existing |
| `existing_topic_arn` | ARN of existing topic (required when `create_topic` is false) |
| `topic_name` | SNS topic name (required when `create_topic` is true) |
| `environment` | Environment label |
| `subscriptions` | Map of subscription_key → config (protocol, endpoint, `lambda_function_name` for lambda) |
| `fifo_topic` | Create FIFO topic (default false) |

| Output | Description |
|---|---|
| `topic_arn` | SNS topic ARN (created or existing) |
| `topic_name` | SNS topic name (null when using existing topic) |

**Usage examples:**

Create new topic:

```hcl
module "sns" {
  source      = "../../modules/sns"
  topic_name  = "my-topic"
  environment = "dev"
  subscriptions = { ... }
}
```

Subscribe to existing external topic:

```hcl
module "sns_external" {
  source             = "../../modules/sns"
  create_topic       = false
  existing_topic_arn = "arn:aws:sns:us-east-1:123456789012:External-Topic"
  environment        = "dev"
  subscriptions = {
    lambda = {
      protocol             = "lambda"
      endpoint             = module.lambda.function_arn
      lambda_function_name = module.lambda.function_name
    }
  }
}
```

### 9.7 `modules/dynamodb`

| Input | Description |
|---|---|
| `table_name` | DynamoDB table name |
| `hash_key`, `hash_key_type` | Partition key (default `request_id`, `S`) |
| `range_key`, `range_key_type` | Optional sort key |
| `billing_mode` | `PAY_PER_REQUEST` or `PROVISIONED` |
| `point_in_time_recovery` | Enable PITR |
| `server_side_encryption_enabled` | SSE at rest |
| `default_tags`, `managed_by_tag` | Tag overrides |

| Output | Description |
|---|---|
| `table_name` | Table name |
| `table_arn` | Table ARN |

