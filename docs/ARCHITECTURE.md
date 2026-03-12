# Architecture Document — Multi-Region Serverless Stack

## 1. Overview

This project implements a cost-optimised, event-driven serverless architecture deployed across two AWS regions. It demonstrates multi-region active–active deployment, JWT-authenticated APIs, SNS fan-out, DynamoDB audit logging, and ECS Fargate task orchestration — all provisioned through modular Terraform.

This document is a **technical companion** to [`README.md`](/README.md):
- [`README.md`](/README.md) focuses on getting started, workflows, and how to run/test the stack.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) explains how the system is structured internally and why specific design decisions were made.

---

## 2. Regions

| Region | Role |
|---|---|
| `us-east-1` | Primary — hosts Cognito, full compute stack |
| `eu-west-1` | Secondary — full compute stack, shares Cognito from us-east-1 |

Cognito (authentication) is intentionally deployed in **us-east-1 only**. All JWT tokens issued there are valid for API Gateway authorizers in both regions because the authorizer validates the token signature against Cognito's JWKS endpoint — no regional duplication required.

---
## 3. Request Flow Diagrams

### 3.1 GET /greet request flow

```
Client
  │
  │  GET /greet
  │  Authorization: Bearer <JWT>
  ▼
API Gateway (HTTP API)
  │
  │  JWT validated against Cognito JWKS
  ▼
Greeter Lambda
  │
  │  sns.publish(USER_GREETED)
  ▼
SNS Topic
  ├──────────────────────────────────────┐
  │  email subscription                  │  lambda subscription
  ▼                                      ▼
Email inbox                       Dispatcher Lambda
                                          │
                              ┌───────────┴────────────┐
                              │                        │
                              ▼                        ▼
                         DynamoDB               ECS Fargate task
                      (audit record)          (aws sns publish)
                                                       │
                                                       ▼
                                                  SNS Topic
                                                  (email inbox)
```

### 3.2 GET /dispatch request flow

```
Client
  │
  │  GET /dispatch
  │  Authorization: Bearer <JWT>
  ▼
API Gateway (HTTP API)
  │
  ▼
Dispatcher Lambda
  │  (synthesises USER_GREETED from env vars)
  │
  ├──────────────────┐
  │                  │
  ▼                  ▼
DynamoDB       ECS Fargate task
(audit)        (aws sns publish → SNS Topic → email)
```

---

## 4. Component Breakdown

### 4.1 Authentication — Cognito

- **User Pool**: stores user identities, enforces configurable password policy; schema attributes (default: email) are configurable via `schema_attributes`
- **App Client**: `ALLOW_USER_PASSWORD_AUTH` flow, no client secret (public client)
- **Test user**: provisioned via Terraform with `email_verified = true`; password set permanently via `admin-set-user-password` (null_resource with retries for Cognito eventual consistency)
- **JWT tokens**: API Gateway v2 validates the `IdToken` using the pool's issuer URL and client ID

### 4.2 API Gateway (HTTP API v2)

One HTTP API per region. Each API has:

| Route | Integration | Auth |
|---|---|---|
| `GET /greet` | Greeter Lambda (AWS_PROXY) | Cognito JWT |
| `GET /dispatch` | Dispatcher Lambda (AWS_PROXY) | Cognito JWT |

The JWT authorizer is configured with the Cognito issuer URL and client ID. Requests without a valid `Authorization: Bearer <token>` header receive `401 Unauthorized`.

### 4.3 Greeter Lambda (`services/greeter-lambda/app.py`)

**Runtime:** Python 3.12  
**Trigger:** API Gateway `GET /greet`  
**Responsibilities:**
- Reads `SNS_TOPIC_ARN`, `USER_EMAIL`, `REPO_URL` from environment variables
- Publishes a structured `USER_GREETED` event to the regional SNS topic
- Returns `{"region": "<executing_region>"}` to the API caller

**SNS payload (example):**
```json
{
  "type": "USER_GREETED",
  "region": "us-east-1",
  "email": "<user-email>",
  "repo": "https://github.com/org/repo"
}
```

**IAM permissions:** `sns:Publish` on the regional topic, `logs:*`

### 4.4 SNS Topic (per region)

Each region has one SNS topic (`greeter-verification-<region>`) with two subscriptions:

| Subscription | Protocol | Purpose |
|---|---|---|
| Email | `email` | Delivers the raw `USER_GREETED` JSON directly to the configured email address |
| Lambda | `lambda` | Invokes the Dispatcher Lambda asynchronously |

#### External Topic Integration

> **Important Feature**: The SNS module supports both creating new topics and subscribing to existing external topics (including cross-account scenarios). This allows Lambda functions to react to events from topics managed outside this stack.

**Use cases:**
- Subscribe to organization-wide event topics
- Integrate with third-party SNS topics
- React to events from other AWS accounts
- Connect to legacy systems publishing to SNS

**Example**: To subscribe to an external topic like `arn:aws:sns:us-east-1:124456789012:external-events-topic`, set `create_topic = false` and provide the `existing_topic_arn`. The module automatically creates the necessary Lambda permissions and subscriptions.

### 4.5 Dispatcher Lambda (`services/dispatcher-lambda/app.py`)

**Runtime:** Python 3.12  
**Triggers:** SNS subscription (async) _and_ API Gateway `GET /dispatch` (direct)  
**Responsibilities:**

| Trigger | Behaviour |
|---|---|
| SNS | Parses `Records[*].Sns.Message`, processes `USER_GREETED` events |
| API Gateway | Synthesises a `USER_GREETED` event from its own env vars |

For every `USER_GREETED` event, the Dispatcher:
1. Writes an audit record to **DynamoDB** (`request_id`, `timestamp`, `region`, `event_type`, `email`)
2. Launches an **ECS Fargate** task with the event details

**IAM permissions:** `dynamodb:PutItem`, `ecs:RunTask`, `iam:PassRole` (for ECS roles), `logs:*`

### 4.6 DynamoDB (per region)

| Attribute | Value |
|---|---|
| Table name | `greeting-logs-<region>` |
| Billing | `PAY_PER_REQUEST` (no provisioned capacity) |
| Hash key | `request_id` (String) |
| TTL | Not configured (audit logs retained indefinitely) |

### 4.7 ECS Fargate (per region)

**Cluster:** `{project_name}-cluster-<region>` (default project: `unleash`)  
**Image:** `public.ecr.aws/aws-cli/aws-cli:latest`  
**Launch type:** Fargate (serverless compute — no EC2 instances)  
**Network:** Public subnet, `assignPublicIp: ENABLED` (no NAT gateway required)  
**Security group:** Dedicated SG with outbound-only rules (image pull, CloudWatch Logs, SNS)

The **ECS module** creates only the cluster and task definition. The caller (dev `main.tf`) provides:
- IAM roles (execution + task) from the IAM module
- Security group, log group, and container definitions JSON

The task definition overrides the default `aws` entrypoint with `sh -c` and runs:

```bash
MSG=$(printf '{"email":"%s","source":"ECS","region":"%s","repo":"%s"}' \
      "$USER_EMAIL" "$AWS_DEFAULT_REGION" "$REPO_URL")

aws sns publish \
  --topic-arn "$SNS_TOPIC_ARN" \
  --message "$MSG" \
  --region "$AWS_DEFAULT_REGION"

echo SNS_PUBLISH_COMPLETE
```

**SNS payload from ECS (example):**
```json
{
  "email": "<user-email>",
  "source": "ECS",
  "region": "us-east-1",
  "repo": "https://github.com/org/repo"
}
```

The task exits cleanly after publishing. CloudWatch Logs capture all output under `/ecs/ecs-task-<region>` with configurable retention.

**ECS IAM roles:**

| Role | Purpose | Key policies |
|---|---|---|
| Task Execution Role | ECS control plane: pull image, write logs | `AmazonECSTaskExecutionRolePolicy` |
| Task Role | Container runtime permissions | `sns:Publish`, `logs:*` |

### 4.8 Networking (per region)

Dedicated VPC per region — no default VPC dependency.

| Resource | Value |
|---|---|
| VPC CIDR (us-east-1) | `10.0.0.0/16` |
| VPC CIDR (eu-west-1) | `10.1.0.0/16` |
| Public subnets | 3 AZs per region (`/24` each) |
| Internet Gateway | Yes |
| NAT Gateway | **No** — ECS tasks use public subnets with public IPs (cost optimised) |
| VPC Endpoint (CloudWatch Logs) | Interface endpoint in public subnets — ECS Fargate streams logs via PrivateLink |

Lambda functions run outside the VPC — they use AWS-managed networking to reach DynamoDB, SNS, and ECS via public AWS endpoints. ECS tasks use the CloudWatch Logs VPC endpoint to stream logs without requiring internet egress.

---


## 5. Security Design

| Area | Decision | Rationale |
|---|---|---|
| Authentication | Cognito JWT (RS256) | Stateless, no session management, easy to revoke |
| API authorisation | JWT required on all routes | No public endpoints exposed |
| Lambda IAM | Inline least-privilege policies | Each Lambda has only the permissions it needs |
| ECS Task Role | `sns:Publish` scoped to topic ARN | Container cannot access other AWS resources |
| Networking | Lambdas outside VPC; ECS in public subnet | Simpler, cheaper; no sensitive data in transit within VPC |
| Secrets | Terraform variables + GitHub environment secrets | No credentials hardcoded in code or IaC |
| State | S3 remote backend with versioning | Prevents state loss; supports team collaboration |

---
