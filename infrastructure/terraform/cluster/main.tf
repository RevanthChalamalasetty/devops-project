terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Stack     = "cluster"
      ManagedBy = "terraform"
    }
  }
}

# Read outputs from the persistent stack
data "terraform_remote_state" "persistent" {
  backend = "s3"
  config = {
    bucket = var.tf_state_bucket
    key    = "persistent/terraform.tfstate"
    region = var.aws_region
  }
}

locals {
  vpc_id           = data.terraform_remote_state.persistent.outputs.vpc_id
  public_subnet_id = data.terraform_remote_state.persistent.outputs.public_subnet_id
  jenkins_role_arn = data.terraform_remote_state.persistent.outputs.jenkins_role_arn
}
