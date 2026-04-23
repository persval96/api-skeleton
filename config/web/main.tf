terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "persval96-dev-terraform-tfstate-eu-west-3"
    key     = "api-skeleton.tfstate"
    region  = "eu-west-3"
    encrypt = true
  }

}