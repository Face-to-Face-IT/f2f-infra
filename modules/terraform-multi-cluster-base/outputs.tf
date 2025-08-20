################################################################################
# External DNS Outputs
################################################################################

output "external_dns_role_arn" {
  description = "ARN of the External DNS IAM role"
  value       = aws_iam_role.external_dns.arn
}

################################################################################
# AWS Load Balancer Controller Outputs
################################################################################

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.lbc.arn
}

################################################################################
# External Secrets Operator Outputs
################################################################################

output "external_secrets_role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = aws_iam_role.external_secrets.arn
}

output "cluster_secrets_arn" {
  description = "ARN of the cluster-specific secrets in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.cluster_secrets.arn
}

output "github_credentials_secret_arn" {
  description = "ARN of the GitHub credentials secret in AWS Secrets Manager"
  value       = var.create_github_secret ? aws_secretsmanager_secret.github_credentials[0].arn : null
}


################################################################################
# Webhook URLs
################################################################################

output "receiver_webhook_url" {
  description = "Webhook URL for GitHub receiver (app-preview)"
  value       = "https://flux-webhook.${var.cluster_domain}/hook/${random_password.receiver_token.result}"
  sensitive   = true
}

output "flux_webhook_url" {
  description = "Webhook URL for Flux system webhooks"
  value       = "https://flux-webhook.${var.cluster_domain}/hook/${random_password.webhook_token.result}"
  sensitive   = true
}

################################################################################
# Cluster Information
################################################################################

output "cluster_name" {
  description = "Name of the cluster"
  value       = var.name
}

output "cluster_domain" {
  description = "Domain name for the cluster"
  value       = var.cluster_domain
}
