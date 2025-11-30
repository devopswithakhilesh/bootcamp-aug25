terraform {
  required_version = ">= 1.0.0" # from 1.0.0 - 1.9.9
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}