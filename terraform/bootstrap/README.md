
# How this `terraform/boostrap` was created

📂 Target File Layout: `terraform/bootstrap/`

```text
terraform/bootstrap/
├── providers.tf      # AWS Provider configuration
├── backend.tf        # S3 Backend to store tfstate file (-migrate-state)
├── main.tf           # S3 State Bucket & DynamoDB Lock Table
├── oidc.tf           # GitHub/GitLab OIDC Trust & Deployment Roles
├── outputs.tf        # ARNs and names to plug into subsequent steps
└── terraform.tfvars  # Input variables (region, project name, etc.)
```

## 🛠️ The Bootstrap Terraform Code

### 1. `providers.tf`

Because this is the very first deployment, this directory will use a **local** state file initially. Once these resources are created, you will migrate your state to the newly created S3 bucket.

```terraform
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 2. `main.tf` (State Backend Infrastructure)

This provisions the backend architecture where all subsequent layers (`management/`, `network/`) will safely lock and store their state files.

```terraform
# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "triton-enterprise-tfstate"
  force_destroy = true # Set to false in actual production environments

  lifecycle {
    prevent_destroy = false # Allowed for your cost-optimization strategy
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "triton-enterprise-tflocks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 3. `oidc.tf` (Secure Passwordless CI/CD)

Since your environment connects to external repositories, we establish an OpenID Connect (OIDC) trust relationship. This example is configured for **GitHub**, but can easily match GitLab by tweaking the issuer URL.

```terraform
# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"] # Standard GitHub OIDC Thumbprint
}

# Central IAM Deployment Role assumed by CI/CD Pipelines
resource "aws_iam_role" "cicd_deployment_role" {
  name = "TritonCentralDeploymentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Limits execution exclusively to your Triton infrastructure repository
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_organization_or_user}/project-triton-*:*"
          }
        }
      }
    ]
  })
}

# Attach Administrator Access to this role so it can build the Landing Zone / Organization
resource "aws_iam_role_policy_attachment" "cicd_admin_attach" {
  role       = aws_iam_role.cicd_deployment_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

### 4. `outputs.tf`

```terraform 
output "tfstate_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket for tracking backend configurations"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.id
  description = "Name of the DynamoDB state locking table"
}

output "cicd_deployment_role_arn" {
  value       = aws_iam_role.cicd_deployment_role.arn
  description = "ARN of the IAM role for GitHub Actions / GitLab workflows to assume"
}
```

### 5. `variables.tf`

This file explicitly defines the inputs your bootstrap layer expects, enforcing type safety and providing documentation for your configuration blocks.

```terraform
variable "aws_region" {
  type        = string
  description = "The target AWS region where core bootstrap resources will be created"
  default     = "sa-east-1"
}

variable "github_organization_or_user" {
  type        = string
  description = "Your personal GitHub username or organization holding the Triton repositories"
}
```

### 6. `terraform.tfvars.example`

This file feeds your real-world configurations into the variables block. **Modify these placeholder values to match your actual environment.**

```terraform
# The target execution footprint region
aws_region = "sa-east-1"

# Replace with your exact GitHub or GitLab profile name where code is pushed
github_organization_or_user = "YOUR-GITHUB-ACCOUNT"
```

## 🚀 Execution Strategy

```bash 
cd terraform/bootstrap
terraform init
terraform apply

# check if the bucket was created
$ aws s3 ls
2026-07-02 23:56:24 triton-enterprise-tfstate

```

## Migrate TFSTATE to S3 after initial creation

**The State Migration Step:** Once applied, you can migrate your local `terraform.tfstate` up to the newly built cloud bucket by creating a `backend.tf` file right inside this directory and running `terraform init` again to push the state file into AWS.

### 1 . `backend.tf`

```terraform
terraform {
  backend "s3" {
    bucket         = "triton-enterprise-tfstate" 
    key            = "bootstrap/terraform.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "triton-enterprise-tflocks"
    encrypt        = true
  }
}
```

### 2. Execution 
```bash 
terraform init -migrate-state
```

### 3. Delete old `.tfstate` file

Now you can delete/move your `terraform.tfstate` and `terraform.tfstate.backup` files 

```bash 
mv terraform.tfstate* /tmp/

$ tree
.
├── README.md
├── backend.tf
├── main.tf
├── oidc.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── terraform.tfvars.example
└── variables.tf

```

### 4. Try `terraform plan` to check

```bash 
$ terraform plan 
...
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are
needed.
```


