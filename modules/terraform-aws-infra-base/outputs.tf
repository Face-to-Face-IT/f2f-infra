output "cluster_region" {
  value = var.region
}

output "cluster_name" {
  value = var.cluster_name
}

output "cluster_endpoint" {
  value = module.eks_bottlerocket.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks_bottlerocket.cluster_certificate_authority_data
}

output "cluster_auth_token" {
  value = data.aws_eks_cluster_auth.this.token
}

output "cluster_oidc_provider" {
  value = module.eks_bottlerocket.oidc_provider
}

output "prometheus_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID"
  value       = aws_prometheus_workspace.this.id
}

output "prometheus_workspace_endpoint" {
  description = "Amazon Managed Prometheus workspace endpoint"
  value       = aws_prometheus_workspace.this.prometheus_endpoint
}

output "prometheus_iam_role_arn" {
  description = "IAM role ARN for Prometheus service account"
  value       = aws_iam_role.prometheus.arn
}
