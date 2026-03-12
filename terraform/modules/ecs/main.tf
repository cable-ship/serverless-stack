locals {
  task_definition_family = coalesce(var.task_definition_family, "ecs-task-${var.region}")
  cluster_name           = coalesce(var.cluster_name, "${var.cluster_name_prefix}-${var.region}")
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/ecs-task-${var.region}"
  retention_in_days = var.ecs_log_retention_in_days

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_security_group" "ecs_task" {
  name        = "ecs-task-${var.region}"
  description = "Allow ECS Fargate task outbound traffic"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.task_definition_family
  requires_compatibilities = var.requires_compatibilities
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = var.container_definitions

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}
