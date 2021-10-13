variable "app_name" {
  description = "Application name"
  type = string
}

variable "env_name" {
  description = "Application environment name"
  type = string
}

variable "app_server_port" {
  description = "Application server port"
  type        = number
}

variable "newrelic_license_key" {
  description = "NewRelic license key"
  type = string
}
