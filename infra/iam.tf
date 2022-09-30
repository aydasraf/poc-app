data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "ecs_task_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.service_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role.json
}

data "aws_iam_policy_document" "secret_manager_access" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.terraform_remote_state.rds.outputs.url_shortener_secret, "arn:aws:secretsmanager:eu-west-1:648742428820:secret:url_shortner-Qyxxnz"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "cwlogs_access" {
  statement {
    actions = [
      "logs:CreateLog*",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "secret_manager_access" {
  name   = "${local.service_name}-task-role-secret-manager-access"
  policy = data.aws_iam_policy_document.secret_manager_access.json
}

resource "aws_iam_policy" "cwlogs_access" {
  name   = "${local.service_name}-task-role-cwlogs-access"
  policy = data.aws_iam_policy_document.cwlogs_access.json
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment-execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secret-manager-access-policy-attachment-execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secret_manager_access.arn
}

resource "aws_iam_role_policy_attachment" "cwlogs-access-policy-attachment-execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.cwlogs_access.arn
}

resource "aws_iam_role_policy_attachment" "cwlogs-access-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.cwlogs_access.arn
}