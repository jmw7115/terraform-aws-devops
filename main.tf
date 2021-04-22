terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" { # terraform aws provider
  profile = "default"
  region  = var.aws_region
}

