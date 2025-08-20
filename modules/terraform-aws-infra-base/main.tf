data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

}

################################################################################
# EKS
################################################################################

module "eks_bottlerocket" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # EKS Addons
  cluster_addons = {
    coredns = {
      version = var.cluster_addon_coredns.version
    }
    eks-pod-identity-agent = {
      addon_version = var.cluster_addon_pod_identity_agent.version
    }
    kube-proxy = {
      addon_version = var.cluster_addon_kube_proxy.version
    }
    vpc-cni = {
      addon_version = var.cluster_addon_vpc_cni.version
    }
  }

  cluster_endpoint_public_access  = var.cluster_public_access
  cluster_endpoint_private_access = var.cluster_private_access

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      ami_type       = var.cluster_ami_type
      instance_types = var.cluster_instance_types
      min_size       = var.cluster_min_size
      max_size       = var.cluster_max_size
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size  = 2
      capacity_type = var.cluster_capacity_type
    }
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_bottlerocket.cluster_name
}

# Note: current_principal role not defined in this module
# resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSAdminPolicy"
#   role       = aws_iam_role.current_principal.name
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_admin_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterAdminPolicy"
#   role       = aws_iam_role.current_principal.name
# }
