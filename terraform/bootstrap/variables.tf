variable "aws_region" {
  type        = string
  description = "The target AWS region where core bootstrap resources will be created"
  default     = "sa-east-1"
}

variable "github_organization_or_user" {
  type        = string
  description = "Your personal GitHub username or organization holding the Triton repositories"
}
