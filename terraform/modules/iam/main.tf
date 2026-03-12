resource "aws_iam_role" "this" {
  for_each = var.roles

  name = each.value.name

  assume_role_policy   = each.value.assume_role_policy
  path                 = each.value.path
  description          = each.value.description
  permissions_boundary = each.value.permissions_boundary
  max_session_duration = each.value.max_session_duration

  tags = merge(
    coalesce(var.default_tags, { Environment = var.environment, ManagedBy = var.managed_by_tag }),
    var.tags
  )
}

resource "aws_iam_role_policy" "this" {
  for_each = merge([
    for role_key, role in var.roles : {
      for policy_name, policy_doc in role.inline_policies :
      "${role_key}-${policy_name}" => {
        role_key    = role_key
        policy_name = policy_name
        policy_doc  = policy_doc
      }
    }
  ]...)

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy_doc
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = merge([
    for role_key, role in var.roles : {
      for i, arn in try(role.managed_policy_arns, []) : "${role_key}-${i}" => {
        role_key   = role_key
        policy_arn = arn
      }
    }
  ]...)

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}
