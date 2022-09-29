resource "random_integer" "http_priority" {
  min = 1
  max = 50000
  keepers = {
    listener_arn = data.terraform_remote_state.lb.outputs.url_shortener_http_listener_arn
  }
}
resource "random_integer" "https_priority" {
  min = 1
  max = 50000
  keepers = {
    listener_arn = data.terraform_remote_state.lb.outputs.url_shortener_http_listener_arn
  }
}

resource "aws_alb_target_group" "tg" {
  name                 = "${local.service_name}-${terraform.workspace}-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.terraform_remote_state.vpc.outputs.vpc_id
  deregistration_delay = 10
  target_type          = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_alb_listener_rule" "http" {
  listener_arn = data.terraform_remote_state.lb.outputs.url_shortener_http_listener_arn
  priority     = random_integer.http_priority.result

  action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  condition {
    host_header {
      values = [
      "${local.service_name}-*.*"]
    }
  }
}

resource "aws_alb_listener_rule" "https" {
  listener_arn = data.terraform_remote_state.lb.outputs.url_shortener_https_listener_arn
  priority     = random_integer.https_priority.result

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.tg.arn
  }
  condition {
    host_header {
      values = [
      "${local.service_name}-*.*"]
    }
  }
}

