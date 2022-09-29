locals {
  service_name             = "url-shortener"
  region                   = "eu-west-1"
  states_bucket            = "ayd-poc-tf-state"
  container_port           = 3000
  container_image_registry = "648742428820.dkr.ecr.eu-west-1.amazonaws.com"
  container_image_repo     = "kutt/url-shortener"
  container_image_version  = "latest"

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/aydasraf/poc-app"
    Team        = "Kutt"
  }
}