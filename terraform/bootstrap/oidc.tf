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
