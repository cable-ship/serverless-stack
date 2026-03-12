# Multi-Region Serverless Stack

A cost-optimized, event-driven serverless architecture deployed across two AWS regions using Terraform. This project demonstrates multi-region active-active deployment, JWT authentication, SNS fan-out patterns, DynamoDB audit logging, and ECS Fargate task orchestration.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cognito (us-east-1 only)                     │
│              User Pool · Client · JWT Authorizer                │
└────────────────────────────┬────────────────────────────────────┘
                             │ JWT Token
              ┌──────────────┴─────────────┐
              │                            │
    ┌─────────▼─────────┐         ┌────────▼────────┐
    │   API Gateway     │         │   API Gateway   │
    │   (us-east-1)     │         │   (eu-west-1)   │
    └─────────┬─────────┘         └───────┬─────────┘
              │                           │
       GET /greet  GET /dispatch    GET /greet  GET /dispatch
              │         │                 │          │
    ┌─────────▼──┐  ┌───▼────────┐  ┌─────▼────┐  ┌──▼────────┐
    │  Greeter   │  │ Dispatcher │  │ Greeter  │  │Dispatcher │
    │  Lambda    │  │  Lambda    │  │ Lambda   │  │ Lambda    │
    └─────┬──────┘  └──────┬─────┘  └────┬─────┘  └─────┬─────┘
          │                │             │              │
          │    ┌───────────┼─────────────┘              │
          │    │           │                            │
          ▼    ▼           ▼                            ▼
    ┌─────────────┐  ┌──────────┐              ┌──────────────┐
    │ SNS Topic   │  │ DynamoDB │              │  SNS Topic   │
    │ (Regional)  │  │  Table   │              │  (Regional)  │
    └──────┬──────┘  └──────────┘              └───────┬──────┘
           │                                           │
      ┌────┴────┐                                 ┌────┴────┐
      ▼         ▼                                 ▼         ▼
   Email    ECS Fargate                        Email    ECS Fargate
  Notify      Task                            Notify      Task
              │                                           │
              └───────────► SNS Publish ◄─────────────────┘
```

**Key Features:**

- Multi-region active-active deployment
- Shared Cognito authentication across regions
- Event-driven architecture with SNS fan-out
- Audit logging in DynamoDB per region
- Serverless container orchestration with ECS Fargate

For a deeper technical breakdown of components and data flow, Please refer [ARCHITECTURE.md](docs/ARCHITECTURE.md).

### Deployment Regions

- **Primary (us-east-1)**: Hosts Cognito + full compute stack
- **Secondary (eu-west-1)**: Full compute stack, shares Cognito from us-east-1

## Project Structure

```
├── .github/workflows/          # CI/CD pipeline
├── services/                   # Lambda function source code
│   ├── greeter-lambda/         # Greeting service Lambda
│   └── dispatcher-lambda/      # Event dispatcher Lambda
├── terraform/                  # Infrastructure as Code
│   ├── environments/dev/       # Development environment
│   └── modules/                # Reusable Terraform modules
├── scripts/                    # Utility scripts
└── docs/                       # Project documentation
    ├── ARCHITECTURE.md         # Detailed technical architecture
    ├── TERRAFORM_SETUP.md      # Terraform setup and usage
    └── CI_CD.md                # CI/CD pipeline details
```

## Quick Start

### Prerequisites

- **AWS account & IAM role**: Permissions to create IAM, Lambda, API Gateway, SNS, DynamoDB, ECS, VPC, and S3 resources. For CI, an OIDC-assumable role (`AWS_OIDC_ROLE_ARN` secret).
- **AWS CLI configured with appropriate permissions**: Installed and configured (profile or environment variables).
- **Terraform >= 1.7.5**.
- **Python 3.12** (for Lambda packaging and tooling).
- **Required tools**: `curl`, `jq`, `zip`.
- **GitHub Actions secrets (if using CI)**: `TF_STATE_BUCKET`, `TF_VAR_USER_EMAIL`, `TF_VAR_REPO_URL`, `TEST_PASSWORD`, `AWS_OIDC_ROLE_ARN` (see [CI_CD.md](docs/CI_CD.md)).
- **Test user credentials**: A Cognito user email and password to use via `TEST_USERNAME` / `TEST_PASSWORD` when running integration tests.

### Initial Deployment Steps

1. **Clone the repository**
  ```bash
   git clone <repository-url>
   cd <repository-name>
  ```
2. **Configure Terraform variables**
  Per-region settings: edit `terraform/environments/dev/<region>/terraform.tfvars` (e.g. `us-east-1/terraform.tfvars`, `eu-west-1/terraform.tfvars`) with `region`, networking, `user_email`,`repo_url` etc.
3. **Build Lambda packages**
  ```bash
   cd services/greeter-lambda && zip -j greeter.zip app.py
   cd ../dispatcher-lambda && zip -j dispatcher.zip app.py
  ```
4. **Deploy infrastructure**
  ```bash
   cd terraform/environments/dev
   terraform init
   #for us-east-1
   terraform plan -var-file="us-east-1/terraform.tfvars"
   terraform apply -var-file="us-east-1/terraform.tfvars"
   #for eu-west-1
   terraform plan -var-file="eu-west-1/terraform.tfvars"
   terraform apply -var-file="eu-west-1/terraform.tfvars"
  ```

## Testing

### Integration Tests

```bash
# Test specific region
TEST_REGION=us-east-1 ./scripts/test_endpoints.sh

# Custom credentials (set your own test user and password)
TEST_USERNAME=<your-test-email> TEST_PASSWORD=<your-test-password> ./scripts/test_endpoints.sh
```

### Expected Test Output

```
═══ Serverless Integration Test (us-east-1) ═══

[1/4] Reading Terraform outputs …
[2/4] Authenticating with Cognito (us-east-1) …
  ✓ JWT obtained

[3/4] Calling /greet …
  ✓ greet
    Status: 200  Latency: 134ms  region: us-east-1

[4/4] Calling /dispatch …
  ✓ dispatch
    Status: 200  Latency: 148ms  region: us-east-1

═══ Summary ═══
  Tests passed : 2/2
```

### API Endpoints

- `GET /greet` - Triggers greeting workflow
- `GET /dispatch` - Direct dispatcher invocation

Both endpoints require `Authorization: Bearer <jwt-token>` header.

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) provides:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Push to main                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Lint & Validate │
                    │  - Terraform    │
                    │  - Python       │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Security Scan   │
                    │  - tfsec        │
                    │  - checkov      │
                    └────────┬────────┘
                             │
              ┌──────────────┴─────────────┐
              │                            │
    ┌─────────▼─────────┐         ┌────────▼──────────┐
    │  Plan & Deploy    │         │  Plan & Deploy    │
    │   (us-east-1)     │         │   (eu-west-1)     │
    │  - Build Lambda   │         │  - Build Lambda   │
    │  - Terraform Init │         │  - Terraform Init │
    │  - Terraform Plan │         │  - Terraform Plan │
    │  - Terraform Apply│         │  - Terraform Apply│
    └─────────┬─────────┘         └────────┬──────────┘
              │                            │
    ┌─────────▼─────────┐         ┌────────▼─────────┐
    │ Integration Tests │         │Integration Tests │
    │   (us-east-1)     │         │   (eu-west-1)    │
    │  - Auth with      │         │  - Auth with     │
    │    Cognito        │         │    Cognito       │
    │  - Test /greet    │         │  - Test /greet   │
    │  - Test /dispatch │         │  - Test /dispatch│
    └───────────────────┘         └──────────────────┘
```

**Pipeline Features:**

- **Lint & validate**: Terraform and Python linting/validation on every PR
- **Security scanning**: `tfsec` and `checkov` static analysis of Terraform code
- **Plan & deploy**: Multi-region Terraform `plan`/`apply` using OIDC-based AWS credentials
- **Integration tests**: Runs `./scripts/test_endpoints.sh` against both regions after deployment

For a detailed job-by-job diagram and explanation of conditional behavior, see [CI_CD.md](docs/CI_CD.md).

## Terraform Modules

This project uses reusable Terraform modules for infrastructure provisioning:


| Module          | Purpose                                                                   |
| --------------- | ------------------------------------------------------------------------- |
| **api-gateway** | HTTP API v2 with JWT authorization and route management                   |
| **cognito**     | User pools, app clients, and user management                              |
| **dynamodb**    | Tables with configurable billing and encryption                           |
| **ecs**         | Fargate clusters and task definitions                                     |
| **iam**         | IAM roles with inline and managed policies                                |
| **lambda**      | Lambda functions with optional role creation                              |
| **networking**  | VPC, subnets, internet gateway, and VPC endpoints                         |
| **sns**         | Topic creation or subscription to external topics (cross-account support) |


**Module Features:**

- Configurable via variables (no hardcoded values)
- Support for custom tags and naming conventions
- Built-in validation for required parameters
- Outputs for cross-module references

For detailed module documentation including inputs, outputs, and usage examples, see [TERRAFORM_SETUP.md](docs/TERRAFORM_SETUP.md#10-module-reference).

## Security Features

- **JWT Authentication**: All API endpoints require valid Cognito tokens
- **IAM Least Privilege**: Each service has minimal required permissions
- **VPC Endpoints**: ECS tasks use PrivateLink for CloudWatch Logs
- **Security Scanning**: Automated tfsec and checkov scans in CI/CD

## Cost Optimization

- **No NAT Gateways**: ECS tasks use public subnets (~$32/month savings per region)
- **Pay-per-Request DynamoDB**: No idle capacity costs
- **Serverless Compute**: Lambda and Fargate billed per execution
- **Single Cognito Pool**: Shared across regions to avoid duplication

## Monitoring

- **CloudWatch Logs**: All Lambda and ECS task logs
- **DynamoDB**: Audit trail of all greeting events
- **SNS**: Email notifications for user interactions

## Development

### Local Development

1. Install dependencies: `pip install boto3`
2. Set environment variables for Lambda functions
3. Use AWS CLI for local testing

### Adding New Regions

1. Create new tfvars file in `terraform/environments/dev/<region>/`
2. Update GitHub Actions matrix with new region
3. Deploy using existing Terraform modules

## Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - System design, component breakdown, and data flows
- [TERRAFORM_SETUP.md](docs/TERRAFORM_SETUP.md) - Terraform setup, deployment guide, and module reference
- [CI_CD.md](docs/CI_CD.md) - CI/CD workflow details
- [Terraform Modules](terraform/modules/) - Individual module READMEs with usage examples
- [GitHub Actions workflow](.github/workflows/deploy.yml) - CI/CD pipeline configuration test

