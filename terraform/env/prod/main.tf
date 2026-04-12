terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  name                = var.vpcname
  vpc_cidr            = var.cidr
  az                  = var.az
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "securityGroup" {
  source = "../../modules/securityGroup"

  name   = var.sgname
  vpc_id = module.vpc.vpc_id
}

module "iam" {
  source = "../../modules/iam"

  cluster_name = var.clustername
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "alb" {
  source = "../../modules/alb"

  name              = var.albname
  vpc_id            = module.vpc.vpc_id
  alb_sg_id         = module.securityGroup.alb_sg_id
  public_subnet_ids = module.vpc.public_subnet_ids
  app_port          = 8080
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.clustername
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_cluster_arn    = module.iam.eks_cluster_arn
  node_arn           = module.iam.node_arn
  node_instance_type = var.node_instance_type
  ebs_csi_arn = module.iam.ebs_csi_arn


}
