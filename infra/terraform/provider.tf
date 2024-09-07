terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.65.0"
    }
  }

  # Comment in to use a remote backend
  # Make sure to put in the approriate parameters
  # backend "s3" {
  #   bucket         = ""
  #   key            = "terraform.tfstate"
  #   dynamodb_table = ""

  #   region = ""
  # }
}

provider "aws" {
  region  = var.region
  profile = "terraform"
}