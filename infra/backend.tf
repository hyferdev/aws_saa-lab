terraform {
  required_version = ">= 1.15"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  cloud {
    organization = "Hyfer-Org"
    workspaces {
      name = "aws_saa-lab"
    }
  }
}

