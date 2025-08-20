################################################################################
# External Secrets Operator
################################################################################

resource "aws_iam_policy" "external_secrets" {
  name        = "${var.name}-external-secrets-policy"
  description = "IAM policy for External Secrets Operator to access AWS Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:f2f/github-*",
          "arn:aws:secretsmanager:*:*:secret:f2f/clusters/${var.name}-*",
          "arn:aws:secretsmanager:*:*:secret:f2f/app/*"
        ]
      }
    ]
  })
  
  tags = {
    Environment = var.environment
    Project     = "f2f"
    Cluster     = var.name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "external_secrets" {
  name = "${var.name}-external-secrets-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.this.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account_name}"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = {
    Environment = var.environment
    Project     = "f2f"
    Cluster     = var.name
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

################################################################################
# AWS Secrets Manager Secrets
################################################################################

# Generate secure random tokens for this cluster
resource "random_password" "receiver_token" {
  length  = 32
  special = true
}

resource "random_password" "webhook_token" {
  length  = 32
  special = true
}

# Cluster-specific secrets
resource "aws_secretsmanager_secret" "cluster_secrets" {
  name                    = "f2f/clusters/${var.name}"
  description             = "Cluster-specific secrets for ${var.name}"
  recovery_window_in_days = var.secrets_recovery_window_days
  
  tags = {
    Environment = var.environment
    Project     = "f2f"
    Cluster     = var.name
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "cluster_secrets" {
  secret_id = aws_secretsmanager_secret.cluster_secrets.id
  secret_string = jsonencode({
    receiver_token = random_password.receiver_token.result
    webhook_token  = random_password.webhook_token.result
    cluster_domain = var.cluster_domain
    cluster_name   = var.name
  })
}

# Global GitHub credentials secret (created once, shared across clusters)
resource "aws_secretsmanager_secret" "github_credentials" {
  count = var.create_github_secret ? 1 : 0
  
  name                    = "f2f/github"
  description             = "GitHub credentials for F2F application"
  recovery_window_in_days = var.secrets_recovery_window_days
  
  tags = {
    Environment = var.environment
    Project     = "f2f"
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "github_credentials" {
  count = var.create_github_secret ? 1 : 0
  
  secret_id = aws_secretsmanager_secret.github_credentials[0].id
  secret_string = jsonencode({
    username = var.github_username
    token    = var.github_token
    email    = var.github_email
  })
}

