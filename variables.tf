variable "newrelic_account_id" {
  description = "NewRelic account ID"
  type = string
}

variable "newrelic_license_key" {
  description = "NewRelic license key"
  type = string
}

variable "aws_region" {
  description = "AWS region"
  type = string
  default = "us-west-2"
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type = string
  default = "ExampleAppServerInstance"
}

variable "app_server_port" {
  description = "Application server port"
  type        = number
  default     = 8000
}

variable "app_name" {
  description = "Application name"
  type = string
  default = "InventoryApp"
}

variable "env_name" {
  description = "Application environment name"
  type = string
  default = "Dev"
}
