module "networking" {
  source = "../../modules/networking"

  vpc_name       = "${var.project_name}-vpc-${var.region}"
  cidr           = var.vpc_cidr
  azs            = var.azs
  public_subnets = var.public_subnets
  environment    = var.environment
  region         = var.region
  tags           = local.common_tags
}

module "cognito" {
  source = "../../modules/cognito"

  environment = var.environment
  tags        = local.common_tags

  pools = {
    main = {
      name                    = var.cognito_user_pool_name
      password_minimum_length = var.cognito_password_minimum_length
      clients = {
        app = {
          name = var.cognito_user_pool_client_name
        }
      }
      users = var.cognito_create_test_user ? {
        test = {
          username               = var.cognito_user_email
          temporary_password     = var.cognito_test_user_temporary_password
          set_permanent_password = var.cognito_test_user_set_permanent_password
        }
      } : {}
    }
  }
}

module "sns" {
  source = "../../modules/sns"

  create_topic       = var.external_sns_topic_arn == "" ? true : false
  existing_topic_arn = var.external_sns_topic_arn == "" ? null : var.external_sns_topic_arn
  topic_name         = "${var.sns_topic_name_prefix}-${var.region}"
  environment        = var.environment
  tags               = local.common_tags

  create_email_subscription = false
  subscriptions = merge(
    {
      dispatcher = {
        protocol             = "lambda"
        endpoint             = module.lambda["dispatcher"].function_arn
        lambda_function_name = module.lambda["dispatcher"].function_name
      }
    },
    var.enable_email_notifications ? {
      email = {
        protocol = "email"
        endpoint = var.notification_email
      }
    } : {}
  )
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name                     = "${var.dynamodb_table_name_prefix}-${var.region}"
  hash_key                       = var.dynamodb_hash_key
  billing_mode                   = var.dynamodb_billing_mode
  point_in_time_recovery         = var.dynamodb_point_in_time_recovery
  server_side_encryption_enabled = var.dynamodb_server_side_encryption
  environment                    = var.environment
  tags                           = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  region                    = var.region
  environment               = var.environment
  cluster_name              = "${var.project_name}-cluster-${var.region}"
  task_cpu                  = var.ecs_task_cpu
  task_memory               = var.ecs_task_memory
  execution_role_arn        = module.iam_base.role_arn["ecs_execution"]
  task_role_arn             = module.iam_base.role_arn["ecs_task"]
  vpc_id                    = module.networking.vpc_id
  ecs_log_retention_in_days = var.ecs_log_retention_in_days
  container_name            = "app"
  container_definitions = templatefile("${path.module}/templates/ecs-container-definitions.json.tpl", {
    log_group_name  = module.ecs.log_group_name
    region          = var.region
    sns_topic_arn   = module.sns.topic_arn
    user_email      = var.notification_email
    repo_url        = var.repo_url
    container_image = var.ecs_container_image
    container_name  = "app"
  })
  tags = local.common_tags
}

module "iam_base" {
  source = "../../modules/iam"

  environment = var.environment
  tags        = local.common_tags

  roles = {
    ecs_execution = {
      name = "ecs-execution-role-${var.region}"
      path = var.iam_path
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect    = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
            Action    = "sts:AssumeRole"
          }
        ]
      })
      permissions_boundary = var.iam_permissions_boundary
      managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
    }
    ecs_task = {
      name = "ecs-task-role-${var.region}"
      path = var.iam_path
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect    = "Allow"
            Principal = { Service = "ecs-tasks.amazonaws.com" }
            Action    = "sts:AssumeRole"
          }
        ]
      })
      permissions_boundary = var.iam_permissions_boundary
      inline_policies = {
        main = templatefile("${path.module}/policies/ecs-task-policy.json.tpl", {
          sns_topic_arn = module.sns.topic_arn
        })
      }
    }
    greeter = {
      name = "greeter-role-${var.region}"
      path = var.iam_path
      assume_role_policy = coalesce(
        var.iam_trust_policy,
        jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect    = "Allow"
              Principal = { Service = "lambda.amazonaws.com" }
              Action    = "sts:AssumeRole"
            }
          ]
        })
      )
      permissions_boundary = var.iam_permissions_boundary
      inline_policies = {
        main = templatefile("${path.module}/${var.iam_greeter_policy_file}", {
          sns_topic_arn = module.sns.topic_arn
        })
      }
    }
    dispatcher = {
      name = "dispatcher-role-${var.region}"
      path = var.iam_path
      assume_role_policy = coalesce(
        var.iam_trust_policy,
        jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect    = "Allow"
              Principal = { Service = "lambda.amazonaws.com" }
              Action    = "sts:AssumeRole"
            }
          ]
        })
      )
      permissions_boundary = var.iam_permissions_boundary
      inline_policies = {
        main = templatefile("${path.module}/${var.iam_dispatcher_policy_file}", {
          table_arn = module.dynamodb.table_arn
        })
      }
    }
  }
}

module "lambda" {
  source   = "../../modules/lambda"
  for_each = local.lambda_functions

  function_name         = each.value.function_name
  role_arn              = each.value.role_arn
  handler               = lookup(each.value, "handler", "app.handler")
  runtime               = var.lambda_runtime
  filename              = each.value.filename
  environment           = var.environment
  tags                  = local.common_tags
  environment_variables = lookup(each.value, "environment_variables", {})
}

module "apigateway" {
  source = "../../modules/api-gateway"

  api_name          = "${var.project_name}-api-${var.region}"
  environment       = var.environment
  cognito_client_id = module.cognito.user_pool_client_id
  cognito_issuer    = module.cognito.issuer_url
  primary_route_key = "greet"

  routes = {
    greet = {
      route_key               = "GET /greet"
      route_path              = "greet"
      lambda_invoke_arn       = module.lambda["greeter"].invoke_arn
      lambda_function_name    = module.lambda["greeter"].function_name
      permission_statement_id = "AllowAPIGatewayInvoke"
    }
    dispatch = {
      route_key               = "GET /dispatch"
      lambda_invoke_arn       = module.lambda["dispatcher"].invoke_arn
      lambda_function_name    = module.lambda["dispatcher"].function_name
      permission_statement_id = "AllowAPIGatewayInvokeSecondary"
    }
  }
  tags = local.common_tags
}

