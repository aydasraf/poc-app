terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket         = "ayd-poc-tf-state"
    region         = "eu-west-1"
    dynamodb_table = "ayd-poc-tf-lock-table"
    key            = "apps/url_shortener.tfstate"
  }
}

provider "aws" {
  region = "eu-west-1"
}
