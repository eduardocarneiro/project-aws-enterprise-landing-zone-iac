variable "aws_region" {
  type        = string
  description = "The target AWS region where core bootstrap resources will be created"
  default     = "sa-east-1"
}

variable "aws_account_id" {
  type        = string
  description = "The 12-digit AWS Management Account ID where these resources reside"
}

variable "github_organization_or_user" {
  type        = string
  description = "Your personal GitHub username or organization holding the Triton repositories"
}
