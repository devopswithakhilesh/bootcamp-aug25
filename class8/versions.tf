terraform {
  required_version = "1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0" # >= 6.0.0 and < 7.0.0
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0" # >= 3.0.0 and < 4.0.0
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      repo         = "August-Terraform"
      organization = "livingdevops"
      team         = "august bootcamp"
      Terraform    = "true"
    }
  }
}
