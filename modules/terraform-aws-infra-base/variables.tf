################################################################################
# Provider
################################################################################

variable "region" {
  default = "us-west-2"
}

################################################################################
# VPC
################################################################################

variable "vpc_name" {
  default = "f2f-test-123"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_single_nat_gateway" {
  type    = bool
  default = true
}

variable "vpc_enable_nat_gateway" {
  type    = bool
  default = true
}

################################################################################
# EKS Cluster
################################################################################

variable "cluster_name" {
  default = "f2f-cluster-test-123"
}
variable "cluster_version" {
  default = "1.33"
}
variable "cluster_ami_type" {
  default = "BOTTLEROCKET_x86_64"
}
variable "cluster_instance_types" {
  default = ["m6i.large"]
}

variable "cluster_min_size" {
  default = 2
}

variable "cluster_max_size" {
  default = 5
}

variable "cluster_capacity_type" {
  default = "SPOT"
}

variable "cluster_private_access" {
  default = true
}

variable "cluster_public_access" {
  default = false
}

################################################################################
# EKS Cluster Addons
################################################################################

variable "cluster_addon_pod_identity_agent" {
  default = {
    version = "v1.3.7-eksbuild.2"
  }
}

variable "cluster_addon_coredns" {
  default = {
    version = "v1.12.1-eksbuild.2"
  }
}

variable "cluster_addon_kube_proxy" {
  default = {
    version = "v1.33.0-eksbuild.2"
  }
}

variable "cluster_addon_vpc_cni" {
  default = {
    version = "v1.19.5-eksbuild.1"
  }
}
