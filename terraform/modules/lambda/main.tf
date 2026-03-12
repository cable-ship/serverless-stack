# Optional IAM role
module "iam_lambda" {
  count  = var.create_role ? 1 : 0
  source = "../iam"

  environment = var.environment
  tags        = var.tags

  roles = {
    lambda = {
      name                 = var.role_config.name
      path                 = var.role_config.path
      assume_role_policy   = var.role_config.assume_role_policy
      inline_policies      = var.role_config.inline_policies
      permissions_boundary = var.role_config.permissions_boundary
    }
  }
}

locals {
  role_arn = var.create_role ? module.iam_lambda[0].role_arn["lambda"] : var.role_arn
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = local.role_arn
  handler       = var.handler
  runtime       = var.runtime

  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  timeout     = var.timeout
  memory_size = var.memory_size

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_lambda_permission" "invocation" {
  for_each = { for i, p in var.invocation_permissions : p.statement_id => p }

  statement_id  = each.value.statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = each.value.principal
  source_arn    = each.value.source_arn
}

resource "aws_lambda_function_event_invoke_config" "this" {
  count = var.event_invoke_config != null && (try(var.event_invoke_config.destination_on_success_arn, null) != null || try(var.event_invoke_config.destination_on_failure_arn, null) != null) ? 1 : 0

  function_name = aws_lambda_function.this.function_name
  qualifier     = "$LATEST"

  destination_config {
    dynamic "on_success" {
      for_each = try(var.event_invoke_config.destination_on_success_arn, null) != null ? [1] : []
      content {
        destination = var.event_invoke_config.destination_on_success_arn
      }
    }
    dynamic "on_failure" {
      for_each = try(var.event_invoke_config.destination_on_failure_arn, null) != null ? [1] : []
      content {
        destination = var.event_invoke_config.destination_on_failure_arn
      }
    }
  }

  maximum_retry_attempts       = try(var.event_invoke_config.maximum_retry_attempts, null)
  maximum_event_age_in_seconds = try(var.event_invoke_config.maximum_event_age_in_seconds, null)
}
