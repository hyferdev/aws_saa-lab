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

provider "aws" {
  region = "us-east-1"

  # Every resource the project creates gets tagged automatically -> easier
  # cost tracking and cleanup, and good Well-Architected hygiene.
  default_tags {
    tags = {
      Project   = "saa-sprint"
      ManagedBy = "terraform"
    }
  }
}
