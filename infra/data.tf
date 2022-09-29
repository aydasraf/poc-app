data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    region = local.region
    bucket = local.states_bucket
    key    = "env://${terraform.workspace}/vpc.tfstate"
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"

  config = {
    region = local.region
    bucket = local.states_bucket
    key    = "env://${terraform.workspace}/ecs.tfstate"
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"

  config = {
    region = local.region
    bucket = local.states_bucket
    key    = "env://${terraform.workspace}/rds.tfstate"
  }
}

data "terraform_remote_state" "redis" {
  backend = "s3"

  config = {
    region = local.region
    bucket = local.states_bucket
    key    = "env://${terraform.workspace}/redis.tfstate"
  }
}

data "terraform_remote_state" "lb" {
  backend = "s3"

  config = {
    region = local.region
    bucket = local.states_bucket
    key    = "env://${terraform.workspace}/lb.tfstate"
  }
}

data "aws_route53_zone" "zone" {
  name         = "aydasraf.link"
  private_zone = false
}

data "aws_ecr_image" "app" {
  repository_name = local.container_image_repo
  image_tag       = local.container_image_version
}