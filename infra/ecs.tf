resource "aws_ecs_task_definition" "main" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn


  container_definitions = jsonencode([
    {
      name      = "${local.service_name}-container"
      image     = "${local.container_image_registry}/${local.container_image_repo}:${local.container_image_version}@${data.aws_ecr_image.app.image_digest}"
      essential = true
      environment = [
        {
          "DB_HOST" : "${data.terraform_remote_state.rds.outputs.url_shortener_instance_endpoint}",
          "DB_NAME" : "url_shortener",
          "REDIS_HOST" : "${data.terraform_remote_state.redis.outputs.redis_endpoint}"
        }
      ]
      secrets = [
        {
          "name" : "DB_USER",
          "valueFrom" : "${data.terraform_remote_state.rds.outputs.url_shortener_secret}:db_user::"
        },
        {
          "name" : "DB_PASSWORD",
          "valueFrom" : "${data.terraform_remote_state.rds.outputs.url_shortener_secret}:db_pass::"
        }
      ]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = local.container_port
        }
      ]
    }
  ])
}

esource "aws_ecs_service" "main" {
  name                               = "${local.service_name}-${terraform.workspace}"
  cluster                            = data.terraform_remote_state.ecs.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true

  network_configuration {
    security_groups  = aws_security_group.ecs_task.id
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnets_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.tg.arn
    container_name   = "${local.service_name}-container"
    container_port   = local.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}