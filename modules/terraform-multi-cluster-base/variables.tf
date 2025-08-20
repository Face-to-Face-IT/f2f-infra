################################################################################
# Common
################################################################################

variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider URL (e.g. https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E)"
  type        = string
}

################################################################################
# Flux
################################################################################


variable "flux_cluster_name" {
  description = "Name of the cluster for Flux bootstrap path"
  type        = string
  default     = ""
}

variable "flux_github_token" {
  description = "Auth token for flux"
  type        = string
}

################################################################################
# Flux Operator
################################################################################


################################################################################
# External DNS
################################################################################


variable "external_dns_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "external-dns"
}

variable "external_dns_service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "external-dns"
}

variable "external_dns_zone_ids" {
  description = "List of Route53 hosted zone IDs ExternalDNS can manage. If empty, allows all."
  type        = list(string)
  default     = []
}

################################################################################
# AWS Load Balancer
################################################################################


variable "load_balancer_controller_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "load_balancer_controller_service_account_name" {
  description = "Kubernetes service account name"
  type        = string
  default     = "aws-load-balancer-controller"
}

################################################################################
# External Secrets Operator
################################################################################

variable "external_secrets_namespace" {
  description = "Kubernetes namespace for External Secrets Operator"
  type        = string
  default     = "flux-system"
}

variable "external_secrets_service_account_name" {
  description = "Kubernetes service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

################################################################################
# Secrets Management
################################################################################

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
}

variable "cluster_domain" {
  description = "Domain name for the cluster (e.g., sandbox-a.f2f.solutions)"
  type        = string
}

variable "secrets_recovery_window_days" {
  description = "Number of days to retain deleted secrets (0 for immediate deletion in dev)"
  type        = number
  default     = 0
}

variable "create_github_secret" {
  description = "Whether to create the global GitHub credentials secret (only one cluster should set this to true)"
  type        = bool
  default     = false
}

# GitHub credentials (only used if create_github_secret is true)
variable "github_username" {
  description = "GitHub username for authentication"
  type        = string
  sensitive   = true
}

variable "github_email" {
  description = "GitHub email for authentication"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub access token"
  type        = string
  sensitive   = true
}