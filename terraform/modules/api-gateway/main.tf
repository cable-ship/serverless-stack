resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = var.protocol_type

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = var.stage_auto_deploy
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.authorization_type == "JWT" ? 1 : 0

  api_id          = aws_apigatewayv2_api.this.id
  authorizer_type = "JWT"
  name            = var.authorizer_name

  identity_sources = var.authorizer_identity_sources

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = var.cognito_issuer
  }
}

locals {
  route_authorizer_id = var.authorization_type == "JWT" ? aws_apigatewayv2_authorizer.jwt[0].id : (var.authorization_type == "CUSTOM" ? var.authorizer_id : null)
}

resource "aws_lambda_permission" "route" {
  for_each = var.routes

  statement_id  = coalesce(each.value.permission_statement_id, "AllowAPIGatewayInvoke-${each.key}")
  action        = var.lambda_permission_action
  function_name = each.value.lambda_function_name
  principal     = var.lambda_permission_principal
  source_arn    = "${aws_apigatewayv2_stage.default.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "route" {
  for_each = var.routes

  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = var.integration_type
  integration_uri    = each.value.lambda_invoke_arn
  integration_method = var.integration_method
}

resource "aws_apigatewayv2_route" "route" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route_key

  target             = "integrations/${aws_apigatewayv2_integration.route[each.key].id}"
  authorization_type = var.authorization_type
  authorizer_id      = local.route_authorizer_id
}
