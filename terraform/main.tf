terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.41.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "one" {
  length    = 1
}

resource "random_pet" "two" {
  length = 1
}

module "s3update_function" {
  source = "./modules/function"

  function_name  = "${terraform.workspace}_s3update_${random_pet.one.id}_${random_pet.two.id}"
  lambda_handler = "s3update"
  source_dir     = "../bin/s3update"
  tags = {
    environment = terraform.workspace
  }
}
