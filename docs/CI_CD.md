# CI/CD Pipeline — Multi-Region Serverless Stack

## 1. Overview

This project uses **GitHub Actions** to:

- Validate Terraform and Lambda code.
- Perform security scanning of Terraform configurations.
- Plan and deploy the stack to multiple AWS regions using OIDC-based credentials.
- Run end-to-end integration tests against the deployed APIs.

The main workflow file lives at `.github/workflows/deploy.yml`.

## 2. Workflow Triggers

- **Push to `main`**:
  - Runs full pipeline: lint/validate, security scan, plan, deploy, integration tests.
- **Pull Requests**:
  - Runs validation and planning only (no deployment or integration tests).

## 3. Jobs

### 3.1 `lint-and-validate`

**Purpose:** Code quality and syntax validation (no AWS credentials required).

**Key steps:**
- Checkout code.
- Install Terraform `1.7.5`.
- Run `terraform fmt -check -recursive terraform/`.
- Run `terraform init -backend=false` and `terraform validate`.
- Install Python `3.12` and `flake8`.
- Lint Lambda code: `services/*/app.py` (max line length 100).

### 3.2 `security-scan`

**Purpose:** Static security analysis of Terraform.

**Key steps:**
- Checkout code.
- Run **tfsec** against `terraform/` (soft-fail mode).
- Install Python and **checkov**.
- Run **checkov** in soft-fail mode, skipping:
  - `CKV_AWS_116` (Lambda DLQ),
  - `CKV_AWS_117` (Lambda VPC).

Findings are surfaced in workflow logs but do not block deployment.

### 3.3 `plan-and-deploy`

**Purpose:** Multi-region Terraform `plan` and `apply`.

**Strategy:**
- Matrix over regions:
  - `us-east-1` (primary, includes Cognito).
  - `eu-west-1` (secondary).

**Key steps (per region):**
- Checkout code.
- Setup Terraform `1.7.5`.
- Configure AWS credentials via GitHub OIDC into an AWS IAM role (for example `arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>`).
- Build Lambda packages:

```bash
cd services/greeter-lambda && zip -j greeter.zip app.py
cd ../dispatcher-lambda && zip -j dispatcher.zip app.py
```

- `terraform init` with S3 backend:

```bash
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=aws-assessment/dev/$REGION.tfstate"
```

- `terraform plan` with:
  - `-var-file="$REGION/terraform.tfvars"`,
  - `-var="user_email=$TF_VAR_USER_EMAIL"`,
  - `-var="repo_url=$TF_VAR_REPO_URL"`,
  - `-out=tfplan`.
- `terraform apply -auto-approve tfplan`.

### 3.4 `integration-tests`

**Purpose:** End-to-end testing of infrastructure per region.

**Key steps:**
- Checkout code.
- Setup Terraform (read outputs).
- Configure AWS credentials (OIDC role).
- `terraform init` to access state.
- Run `./scripts/test_endpoints.sh`:
  - Authenticates against Cognito.
  - Calls `/greet` and `/dispatch`.
  - Validates status codes, payload shape, and region data.

## 4. Secrets and Environment

### 4.1 GitHub Secrets

Configured under **Repository → Settings → Secrets and variables → Actions**:

- `TF_STATE_BUCKET`: S3 bucket name for Terraform state.
- `TF_VAR_USER_EMAIL`: Email used for test user.
- `TF_VAR_REPO_URL`: Repository URL (used in SNS messages).
- `TEST_PASSWORD`: Password for Cognito test user (min 8 chars, mixed case + number).

### 4.2 Environment Variables (workflow)

- `TF_VERSION`: `"1.7.5"`.
- `PYTHON_VERSION`: `"3.12"`.
- `TF_WORKING_DIR`: `"terraform/environments/dev"`.
- `AWS_REGION`: `"us-east-1"` (default).
