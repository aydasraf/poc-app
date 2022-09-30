resource "aws_security_group" "ecs_task" {
  name   = "${local.service_name}-task-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "Allow Traffic from within the VPC"
    protocol    = "tcp"
    from_port   = local.container_port
    to_port     = local.container_port
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {Name = "${local.service_name}-ecs-sg"},
    local.tags
  )
}