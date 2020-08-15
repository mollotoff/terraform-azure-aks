terraform {
  required_version = ">= 0.12.2"
}

provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

data "aws_availability_zones" "available" {
}

locals {
  # cluster_name = "test-eks-spot-${random_string.suffix.result}"
  cluster_name = var.cluster_name
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = var.cluster_name
  cidr                 = "10.2.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.2.0.0/20", "10.2.16.0/20", "10.2.32.0/20"]
  public_subnets       = ["10.2.48.0/20", "10.2.64.0/20", "10.2.80.0/20"]
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source = "../."
  # source  = "terraform-aws-modules/eks/aws"
  # version = "~> 12.2"
  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  subnets         = module.vpc.public_subnets
  # subnets      = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  key_name= var.key_name


  worker_groups_launch_template = [
    {
      name                    = "spot-1"
      # override_instance_types = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
      override_instance_types = ["t3a.medium", "t3.medium"]
      spot_instance_pools     = 2
      asg_max_size            = 3
      asg_desired_capacity    = 1
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot"
      public_ip               = true
    },
  ]
}
