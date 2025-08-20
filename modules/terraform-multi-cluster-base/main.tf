terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "opentofu/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

################################################################################
# Common
################################################################################

data "aws_iam_openid_connect_provider" "this" {
  url = var.oidc_provider_url
}

################################################################################
# External DNS
################################################################################


locals {
  zone_arns = (
    length(var.external_dns_zone_ids) > 0
    ? [for id in var.external_dns_zone_ids : "arn:aws:route53:::hostedzone/${id}"]
    : ["arn:aws:route53:::hostedzone/*"]
  )
}

resource "aws_iam_policy" "external_dns" {
  name        = "${var.name}-external-dns"
  description = "Allow ExternalDNS to manage Route53 records"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = local.zone_arns
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResources"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role" "external_dns" {
  name = "${var.name}-external-dns-irsa"

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
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_service_account_name}"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}


################################################################################
# AWS Load Balancer Controller
################################################################################

resource "aws_iam_policy" "lbc" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.name}"
  description = "IAM policy for AWS Load Balancer Controller (ALB only)"
  policy      = data.aws_iam_policy_document.lbc.json
}

data "aws_iam_policy_document" "lbc" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupEgress",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebAcl",
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lbc" {
  name = "${var.name}-lbc-sa"
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
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.load_balancer_controller_namespace}:${var.load_balancer_controller_service_account_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lbc" {
  role       = aws_iam_role.lbc.name
  policy_arn = aws_iam_policy.lbc.arn
}

################################################################################
# GitOps Repository Bootstrapping
################################################################################

# resource "github_repository_file" "foo" {
#   repository          = github_repository.foo.name
#   branch              = "main"
#   file                = ".gitignore"
#   content             = "**/*.tfstate"
#   commit_message      = "Managed by Terraform"
#   commit_author       = "Terraform User"
#   commit_email        = "terraform@example.com"
#   overwrite_on_create = true
# }

# resource "github_repository_file" "foo" {
#   repository          = github_repository.foo.name
#   branch              = "main"
#   file                = ".gitignore"
#   content             = "**/*.tfstate"
#   commit_message      = "Managed by Terraform"
#   commit_author       = "Terraform User"
#   commit_email        = "terraform@example.com"
#   overwrite_on_create = true
# }

# resource "github_repository_file" "foo" {
#   repository          = github_repository.foo.name
#   branch              = "main"
#   file                = ".gitignore"
#   content             = "**/*.tfstate"
#   commit_message      = "Managed by Terraform"
#   commit_author       = "Terraform User"
#   commit_email        = "terraform@example.com"
#   overwrite_on_create = true
# }


################################################################################
# Flux Operator Installation
################################################################################

resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }
  lifecycle {
    ignore_changes = [metadata]
  }
}

# Optional: Uncomment and configure if you want to use a GitHub/GitLab token or GitHub App for auth
resource "kubernetes_secret" "git_auth" {
  metadata {
    name      = "flux-system"
    namespace = "flux-system"
  }
  data = {
    username = "git"
    password = var.flux_github_token
  }
  type = "Opaque"

  depends_on = [kubernetes_namespace.flux_system]
}

resource "helm_release" "flux_operator" {
  depends_on       = [kubernetes_namespace.flux_system]
  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  wait             = true
  create_namespace = false
}

resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]
  name       = "flux"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  set {
    name  = "instance.distribution.version"
    value = "2.x"
  }
  set {
    name  = "instance.distribution.registry"
    value = "ghcr.io/fluxcd"
  }
  set {
    name  = "instance.components"
    value = "{source-controller,kustomize-controller,helm-controller,notification-controller}"
  }
  set {
    name  = "instance.cluster.type"
    value = "kubernetes"
  }
  set {
    name  = "instance.cluster.multitenant"
    value = "false"
  }
  set {
    name  = "instance.cluster.networkPolicy"
    value = "true"
  }
  set {
    name  = "instance.cluster.domain"
    value = "cluster.local"
  }
  set {
    name  = "instance.sync.kind"
    value = "GitRepository"
  }
  set {
    name  = "instance.sync.url"
    value = "https://github.com/zjpiazza/f2f-gitops.git"
  }
  set {
    name  = "instance.sync.ref"
    value = "refs/heads/main"
  }
  set {
    name  = "instance.sync.path"
    value = "clusters/${coalesce(var.flux_cluster_name, var.name)}"
  }
  set {
    name  = "instance.sync.pullSecret"
    value = "flux-system"
  }
}
