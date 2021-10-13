terraform {
  backend "remote" {
    organization = "michaelpesa"
    workspaces {
      name = "Example-Workspace"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.62"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 2.21.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.aws_region

  default_tags {
    tags = {
      Application = var.app_name
      Environment = var.env_name
    }
  }
}

provider "newrelic" {
  account_id = var.newrelic_account_id
  region     = "US"
}

module "app_cluster" {
  source = "./modules/aws-app-cluster"

  app_name             = var.app_name
  env_name             = var.env_name
  app_server_port      = var.app_server_port
  newrelic_license_key = var.newrelic_license_key
}

module "monitoring" {
  source = "./modules/newrelic-application"

  app_name = var.app_name
  env_name = var.env_name

  # The app servers need to be created before we refer
  # to the application name in NewRelic APM.
  depends_on = [
    module.app_cluster
  ]
}
