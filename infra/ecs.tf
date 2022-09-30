resource "aws_ecs_task_definition" "main" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn


  container_definitions = jsonencode([
    {
      name      = "${local.service_name}-container"
      image     = "${local.container_image_registry}/${local.container_image_repo}:${local.container_image_version}@${data.aws_ecr_image.app.image_digest}"
      essential = true
      environment = [
        {
          "name" : "DB_HOST",
          "value" : "${data.terraform_remote_state.rds.outputs.url_shortener_instance_endpoint}"
        },
        {
          "name" : "DB_PORT",
          "value" : "5432"
        },
        {
          "name" : "DB_NAME",
          "value" : "url_shortener"
        },
        {
          "name" : "REDIS_HOST",
          "value" : "${data.terraform_remote_state.redis.outputs.url_shortener_redis_address}"
        },
        {
          "name" : "REDIS_PORT",
          "value" : "6379"
        },
        {
          "name" : "SITE_NAME"
          "value" : "Url Shortener"
        },
        {
          "name" : "DEFAULT_DOMAIN"
          "value" : "url-shortener-${terraform.workspace}.aydasraf.link"
        },
        {
          "name" : "MAIL_HOST"
          "value" : "smtp.gmail.com"
        },
        {
          "name" : "MAIL_PORT"
          "value" : "587"
        },
        {
          "name" : "LINK_LENGTH"
          "value" : "6"
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
        },
        {
          "name" : "JWT_SECRET"
          "valueFrom" : "arn:aws:secretsmanager:eu-west-1:648742428820:secret:url_shortner-Qyxxnz:jwt::"
        },
        {
          "name" : "MAIL_USER"
          "valueFrom" : "arn:aws:secretsmanager:eu-west-1:648742428820:secret:url_shortner-Qyxxnz:mail_user::"
        },
        {
          "name" : "MAIL_PASSWORD"
          "valueFrom" : "arn:aws:secretsmanager:eu-west-1:648742428820:secret:url_shortner-Qyxxnz:mail_pass::"
        }
      ]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = local.container_port
        }
      ]
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${local.service_name}",
          "awslogs-region" : "eu-west-1",
          "awslogs-stream-prefix" : "awslogs-"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name                               = "${local.service_name}-${terraform.workspace}"
  cluster                            = data.terraform_remote_state.ecs.outputs.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  force_new_deployment               = true

  network_configuration {
    security_groups  = [aws_security_group.ecs_task.id]
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