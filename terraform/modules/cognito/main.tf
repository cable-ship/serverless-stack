resource "aws_cognito_user_pool" "this" {
  for_each = var.pools

  name = coalesce(each.value.name, "${var.environment}-${each.key}")

  password_policy {
    minimum_length                   = each.value.password_minimum_length
    require_uppercase                = each.value.password_require_uppercase
    require_lowercase                = each.value.password_require_lowercase
    require_numbers                  = each.value.password_require_numbers
    require_symbols                  = each.value.password_require_symbols
    temporary_password_validity_days = each.value.temporary_password_validity_days
  }

  auto_verified_attributes = each.value.auto_verified_attributes

  dynamic "schema" {
    for_each = each.value.schema_attributes
    content {
      name                = schema.value.name
      attribute_data_type = schema.value.attribute_data_type
      required            = schema.value.required
      mutable             = schema.value.mutable
    }
  }

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_cognito_user_pool_client" "this" {
  for_each = merge([
    for pool_key, pool in var.pools : {
      for client_key, client in pool.clients :
      "${pool_key}.${client_key}" => {
        pool_key   = pool_key
        client_key = client_key
        client     = client
      }
    }
  ]...)

  user_pool_id = aws_cognito_user_pool.this[each.value.pool_key].id
  name         = coalesce(each.value.client.name, "${var.environment}-${each.value.pool_key}-${each.value.client_key}")

  generate_secret                      = each.value.client.generate_secret
  explicit_auth_flows                  = each.value.client.explicit_auth_flows
  prevent_user_existence_errors        = each.value.client.prevent_user_existence_errors
  enable_token_revocation              = each.value.client.enable_token_revocation
  allowed_oauth_flows_user_pool_client = each.value.client.allowed_oauth_flows_user_pool_client
}

resource "aws_cognito_user" "this" {
  for_each = merge([
    for pool_key, pool in var.pools : {
      for user_key, user in pool.users :
      "${pool_key}.${user_key}" => {
        pool_key = pool_key
        user_key = user_key
        user     = user
      }
    }
  ]...)

  user_pool_id = aws_cognito_user_pool.this[each.value.pool_key].id
  username     = each.value.user.username

  attributes = {
    email          = each.value.user.username
    email_verified = tostring(each.value.user.email_verified)
  }

  temporary_password   = each.value.user.temporary_password
  message_action       = each.value.user.message_action
  force_alias_creation = false
}

data "aws_region" "current" {}

resource "null_resource" "user_permanent_password" {
  for_each = {
    for k, v in merge([
      for pool_key, pool in var.pools : {
        for user_key, user in pool.users : "${pool_key}.${user_key}" => {
          pool_key = pool_key
          user_key = user_key
          user     = user
        }
      }
    ]...) : k => v if try(v.user.set_permanent_password, true)
  }

  triggers = {
    user_pool_id = aws_cognito_user_pool.this[each.value.pool_key].id
    username     = each.value.user.username
    password     = each.value.user.temporary_password
  }

  provisioner "local-exec" {
    command = "bash -lc 'set -euo pipefail; for i in {1..10}; do aws cognito-idp admin-set-user-password --region \"${data.aws_region.current.name}\" --user-pool-id \"${aws_cognito_user_pool.this[each.value.pool_key].id}\" --username \"${each.value.user.username}\" --password \"$COGNITO_PASSWORD\" --permanent && exit 0; sleep 3; done; exit 1'"
    environment = {
      COGNITO_PASSWORD = each.value.user.temporary_password
    }
  }

  depends_on = [aws_cognito_user.this]
}