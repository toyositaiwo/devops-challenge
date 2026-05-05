terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment this block AFTER you create the S3 bucket in Phase 8
  # backend "s3" {
  #   bucket         = "devops-challenge-tf-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
  single_nat  = var.single_nat
  tags        = local.common_tags
}

module "ecr" {
  source      = "../../modules/ecr"
  project     = var.project
  environment = var.environment
  tags        = local.common_tags
}

module "ecs" {
  source             = "../../modules/ecs"
  project            = var.project
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  ecr_repository_url = module.ecr.repository_url
  image_tag          = var.image_tag
  app_port           = var.app_port
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  desired_count      = var.desired_count
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  tags               = local.common_tags
}

module "cloudwatch" {
  source       = "../../modules/cloudwatch"
  project      = var.project
  environment  = var.environment
  aws_region   = var.aws_region
  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
  alb_arn      = module.ecs.alb_arn
  tags         = local.common_tags
}