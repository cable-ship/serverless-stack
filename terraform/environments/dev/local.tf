locals {
  lambda_functions = {
    greeter = {
      function_name = "greeter-${var.region}"
      role_arn      = module.iam_base.role_arn["greeter"]
      filename      = "${path.module}/../../../services/greeter-lambda/greeter.zip"
      environment_variables = {
        SNS_TOPIC_ARN = module.sns.topic_arn
        PAYLOAD_EMAIL = var.cognito_user_email
        REPO_URL      = var.repo_url
      }
    }
    dispatcher = {
      function_name = "dispatcher-${var.region}"
      role_arn      = module.iam_base.role_arn["dispatcher"]
      filename      = "${path.module}/../../../services/dispatcher-lambda/dispatcher.zip"
      environment_variables = {
        TABLE_NAME         = module.dynamodb.table_name
        CLUSTER_NAME       = module.ecs.cluster_name
        TASK_DEF_ARN       = module.ecs.task_definition_arn
        SUBNET_IDS         = jsonencode(module.networking.public_subnet_ids)
        SECURITY_GROUP_IDS = jsonencode([module.ecs.security_group_id])
        CONTAINER_NAME     = module.ecs.container_name
        USER_EMAIL         = var.cognito_user_email
        REPO_URL           = var.repo_url
      }
    }
  }
}

