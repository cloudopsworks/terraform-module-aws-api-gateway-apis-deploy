##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

#################################################################
# Deploy api only if deploy_stage_only is false                 #
#################################################################
resource "aws_api_gateway_rest_api" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && (!local.is_http_api)
  }

  name                         = each.value.name
  body                         = jsonencode(each.value.content)
  disable_execute_api_endpoint = try(var.aws_configuration.disable_execute_api_endpoint, true)
  minimum_compression_size     = try(var.aws_configuration.minimum_compression_size, null)
  put_rest_api_mode            = local.config_endpoint_type == "PRIVATE" ? try(var.aws_configuration.put_rest_api_mode, "overwrite") : "overwrite"
  endpoint_configuration {
    types            = [local.config_endpoint_type]
    vpc_endpoint_ids = try(var.aws_configuration.vpc_endpoint_ids, null)
  }
  tags = local.all_tags
}

resource "aws_api_gateway_deployment" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && (!local.is_http_api)
  }
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  description = "Deployment for ${each.value.name} - ${var.environment} - Fingerprint: ${each.value.sha1}"

  triggers = {
    redeploy = each.value.sha1
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && (!local.is_http_api)
  }
  deployment_id         = aws_api_gateway_deployment.this[each.key].id
  rest_api_id           = aws_api_gateway_rest_api.this[each.key].id
  stage_name            = local.deploy_stage_name
  xray_tracing_enabled  = try(var.aws_configuration.xray_enabled, null)
  cache_cluster_enabled = try(var.aws_configuration.cache_cluster_enabled, null)
  cache_cluster_size    = try(var.aws_configuration.cache_cluster_size, null)
  variables = merge(
    length(data.aws_api_gateway_vpc_link.vpc_link) > 0 ? {
      vpc_link = data.aws_api_gateway_vpc_link.vpc_link[0].id
    } : {},
    local.is_lambda ? {
      lambdaEndpoint = data.aws_lambda_function.lambda_function[each.key].invoke_arn
    } : {},
    {
      for item in each.value.stage_variables :
      item.name => item.value
    }
  )

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logging[each.key].arn
    format = jsonencode({
      "requestId"         = "$context.requestId"
      "extendedRequestId" = "$context.extendedRequestId"
      "ip"                = "$context.identity.sourceIp"
      "caller"            = "$context.identity.caller"
      "user"              = "$context.identity.user"
      "userAgent"         = "$context.identity.userAgent"
      "requestTime"       = "$context.requestTime"
      "httpMethod"        = "$context.httpMethod"
      "resourcePath"      = "$context.resourcePath"
      "status"            = "$context.status"
      "protocol"          = "$context.protocol"
      "stage"             = "$context.stage"
      "responseLength"    = "$context.responseLength"
      "error"             = "$context.error.message"
      "errorType"         = "$context.error.responseType"
      "errorValString"    = "$context.error.validationErrorString"
    })
  }
  tags = local.all_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_method_settings" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && length(try(var.aws_configuration.settings, {})) > 0 && (!local.is_http_api)
  }
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  stage_name  = aws_api_gateway_stage.this[each.key].stage_name
  method_path = "*/*"
  settings {
    logging_level                              = try(var.aws_configuration.settings.logging_level, null)
    metrics_enabled                            = try(var.aws_configuration.settings.metrics_enabled, null)
    data_trace_enabled                         = try(var.aws_configuration.settings.data_trace_enabled, null)
    throttling_burst_limit                     = try(var.aws_configuration.settings.throttling_burst_limit, null)
    throttling_rate_limit                      = try(var.aws_configuration.settings.throttling_rate_limit, null)
    caching_enabled                            = try(var.aws_configuration.settings.caching_enabled, null)
    cache_ttl_in_seconds                       = try(var.aws_configuration.settings.cache_ttl_in_seconds, null)
    cache_data_encrypted                       = try(var.aws_configuration.settings.cache_data_encrypted, null)
    require_authorization_for_cache_control    = try(var.aws_configuration.settings.require_authorization_for_cache_control, null)
    unauthorized_cache_control_header_strategy = try(var.aws_configuration.settings.unauthorized_cache_control_header_strategy, null)
  }
}

#################################################################
# Deploy only stage as deploy_stage_only is true                #
#################################################################
data "aws_api_gateway_rest_api" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && (!local.is_http_api)
  }
  name = each.value.name
}

resource "aws_api_gateway_deployment" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true
  }
  rest_api_id = data.aws_api_gateway_rest_api.staged[each.key].id
  description = "Deployment for ${each.value.name} - ${var.environment} - Fingerprint: ${each.value.sha1}"

  triggers = {
    redeploy = each.value.sha1
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && (!local.is_http_api)
  }
  description           = "Stage for ${each.value.name} - ${var.environment}"
  deployment_id         = aws_api_gateway_deployment.staged[each.key].id
  rest_api_id           = data.aws_api_gateway_rest_api.staged[each.key].id
  stage_name            = local.deploy_stage_name
  cache_cluster_enabled = try(var.aws_configuration.cache_cluster_enabled, false)
  variables = merge(length(data.aws_api_gateway_vpc_link.vpc_link) > 0 ? {
    vpc_link = data.aws_api_gateway_vpc_link.vpc_link[0].id
    } : {}, {
    for item in each.value.stage_variables :
    item.name => item.value
  })

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logging[each.key].arn
    format = jsonencode({
      "requestId"         = "$context.requestId"
      "extendedRequestId" = "$context.extendedRequestId"
      "ip"                = "$context.identity.sourceIp"
      "caller"            = "$context.identity.caller"
      "user"              = "$context.identity.user"
      "userAgent"         = "$context.identity.userAgent"
      "requestTime"       = "$context.requestTime"
      "httpMethod"        = "$context.httpMethod"
      "resourcePath"      = "$context.resourcePath"
      "status"            = "$context.status"
      "protocol"          = "$context.protocol"
      "stage"             = "$context.stage"
      "responseLength"    = "$context.responseLength"
      "error"             = "$context.error.message"
      "errorType"         = "$context.error.responseType"
      "errorValString"    = "$context.error.validationErrorString"
    })
  }
  tags = local.all_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_method_settings" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && length(try(var.aws_configuration.settings, {})) > 0 && (!local.is_http_api)
  }
  rest_api_id = aws_api_gateway_rest_api.this[each.key].id
  stage_name  = aws_api_gateway_stage.this[each.key].stage_name
  method_path = "*/*"
  settings {
    logging_level                              = try(var.aws_configuration.settings.logging_level, null)
    metrics_enabled                            = try(var.aws_configuration.settings.metrics_enabled, null)
    data_trace_enabled                         = try(var.aws_configuration.settings.data_trace_enabled, null)
    throttling_burst_limit                     = try(var.aws_configuration.settings.throttling_burst_limit, null)
    throttling_rate_limit                      = try(var.aws_configuration.settings.throttling_rate_limit, null)
    caching_enabled                            = try(var.aws_configuration.settings.caching_enabled, null)
    cache_ttl_in_seconds                       = try(var.aws_configuration.settings.cache_ttl_in_seconds, null)
    cache_data_encrypted                       = try(var.aws_configuration.settings.cache_data_encrypted, null)
    require_authorization_for_cache_control    = try(var.aws_configuration.settings.require_authorization_for_cache_control, null)
    unauthorized_cache_control_header_strategy = try(var.aws_configuration.settings.unauthorized_cache_control_header_strategy, null)
  }
}

