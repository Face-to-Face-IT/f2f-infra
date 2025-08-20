provider "tls" {}

# EKS addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks_bottlerocket.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.29.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
}

# AWS Identity and Access Management (IAM) OpenID Connect (OIDC) provider
# Note: OIDC provider is managed by the EKS module

# IAM
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks_bottlerocket.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_bottlerocket.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_bottlerocket.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

################################################################################
# Amazon Managed Service for Prometheus
################################################################################

# Prometheus workspace
resource "aws_prometheus_workspace" "this" {
  alias = "${var.cluster_name}-prometheus"
  
  tags = {
    Name = "${var.cluster_name}-prometheus"
  }
}

# IAM role for Prometheus service account
resource "aws_iam_role" "prometheus" {
  name               = "${var.cluster_name}-prometheus-irsa"
  assume_role_policy = data.aws_iam_policy_document.prometheus_assume_role.json
}

data "aws_iam_policy_document" "prometheus_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks_bottlerocket.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_bottlerocket.cluster_oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_bottlerocket.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:prometheus:prometheus-server"]
    }
  }
}

# IAM policy for Prometheus to access the workspace
resource "aws_iam_policy" "prometheus" {
  name        = "${var.cluster_name}-prometheus-policy"
  description = "IAM policy for Prometheus to access AMP workspace"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.this.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus" {
  policy_arn = aws_iam_policy.prometheus.arn
  role       = aws_iam_role.prometheus.name
}
