locals {
  topic_arn = var.create_topic ? aws_sns_topic.this[0].arn : var.existing_topic_arn
}

resource "aws_sns_topic" "this" {
  count = var.create_topic ? 1 : 0

  name                        = var.fifo_topic ? "${var.topic_name}.fifo" : var.topic_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_lambda_permission" "sns" {
  for_each = { for k, v in var.subscriptions : k => v if v.protocol == "lambda" }

  statement_id  = "AllowSNSInvoke-${replace(each.key, "/[^a-zA-Z0-9-_]/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = local.topic_arn
}

resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscriptions

  topic_arn = local.topic_arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint

  depends_on = [aws_lambda_permission.sns]
}

resource "aws_sns_topic_subscription" "email" {
  count = var.create_email_subscription && var.email_endpoint != null ? 1 : 0

  topic_arn = local.topic_arn
  protocol  = var.email_subscription_protocol
  endpoint  = var.email_endpoint
}
