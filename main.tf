##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  apis_list = [
    for api in var.apis : {
      for def in var.apigw_definitions : api.name => {
        name            = api.name
        version         = api.version
        mapping         = try(def.mapping, "")
        domain_name     = try(def.domain_name, "")
        authorizers     = try(var.aws_configuration.authorizers, [])
        stage_variables = concat(try(var.aws_configuration.stage_variables, []), try(def.stage_variables, []))
        content = (fileexists("${var.absolute_path}/${var.api_files_dir}/${def.file_name}.json") ?
          jsondecode(file("${var.absolute_path}/${var.api_files_dir}/${def.file_name}.json")) :
        yamldecode(file("${var.absolute_path}/${var.api_files_dir}/${def.file_name}.yaml")))
        sha1 = filesha1(
          fileexists("${var.absolute_path}/${var.api_files_dir}/${def.file_name}.json") ?
          "${var.absolute_path}/${var.api_files_dir}/${def.file_name}.json" :
          "${var.absolute_path}/${var.api_files_dir}/${def.file_name}.yaml"
        )
      } if api.name == def.name && api.version == def.version
    }
  ]
  all_apis_raw               = merge(local.apis_list...)
  deploy_stage_name          = var.aws_configuration.stage
  deploy_stage_only          = try(var.aws_configuration.stage_only, false)
  config_endpoint_type       = try(var.aws_configuration.endpoint_type, "REGIONAL")
  default_log_location       = try(var.aws_configuration.log_location, "/aws/apigateway")
  default_log_retention_days = try(var.aws_configuration.log_retention_days, 30)
  is_lambda                  = try(var.aws_configuration.lambda, false)
  release_name               = try(var.release.name, "default")
  is_http_api                = try(var.aws_configuration.http_api, false)

  components = {
    for apiname, apivalue in local.all_apis_raw : apiname => merge(
      {
        for cname, cvalue in apivalue.content.components : cname => cvalue
        if cname != "securitySchemes"
      },
      {
        "securitySchemes" = {
          for auth in var.aws_configuration.authorizers : auth.name => {
            name                           = "Authorization"
            type                           = "apiKey"
            in                             = "header"
            "x-amazon-apigateway-authtype" = "custom"
            "x-amazon-apigateway-authorizer" = {
              authorizerUri         = data.aws_lambda_function.lambda_authorizer[auth.name].invoke_arn
              identitySource        = try(auth.identity_source, "method.request.header.Authorization")
              authorizerCredentials = data.aws_iam_role.lambda_exec_role[auth.name].arn
              authorizerResultTtlInSeconds : try(auth.result_ttl_seconds, 0)
              type : try(auth.type, "request")
            }
          } if auth.authtype == "lambda"
        }
      }
    )
  }
  all_apis = {
    for apiname, apivalue in local.all_apis_raw : apiname => {
      name            = apivalue.name
      version         = apivalue.version
      mapping         = apivalue.mapping
      domain_name     = apivalue.domain_name
      authorizers     = apivalue.authorizers
      stage_variables = apivalue.stage_variables
      content = merge(apivalue.content,
        {
          components = local.components[apiname]
        }
      )
      sha1 = apivalue.sha1
    }
  }
}

#################################################################
# Lambda Function call catalogue                                #
#################################################################
data "aws_lambda_function" "lambda_function" {
  for_each = {
    for api in local.all_apis : api.name => api
    if local.is_lambda
  }
  function_name = format("%s-%s", local.release_name, var.environment)
}

#################################################################
# Lambda authorizers catalogue                                  #
#################################################################
data "aws_lambda_function" "lambda_authorizer" {
  for_each = {
    for auth in var.aws_configuration.authorizers :
    auth.name => auth
    if auth.authtype == "lambda"
  }
  function_name = each.value.lambda.function
}

data "aws_iam_role" "lambda_exec_role" {
  for_each = {
    for auth in var.aws_configuration.authorizers :
    auth.name => auth
    if auth.authtype == "lambda"
  }
  name = each.value.lambda.exec_role
}


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

resource "aws_apigatewayv2_api" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && local.is_http_api
  }

  name          = each.value.name
  protocol_type = "HTTP"
  body          = jsonencode(each.value.content)
  description   = "API Gateway HTTP API for ${each.value.name} - ${var.environment}"
  tags          = local.all_tags

  cors_configuration {
    allow_credentials = try(var.aws_configuration.cors.allow_credentials, false)
    allow_headers     = try(var.aws_configuration.cors.allow_headers, [])
    allow_methods     = try(var.aws_configuration.cors.allow_methods, ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    allow_origins     = try(var.aws_configuration.cors.allow_origins, ["*"])
    expose_headers    = try(var.aws_configuration.cors.expose_headers, [])
    max_age           = try(var.aws_configuration.cors.max_age, null)
  }
}

resource "aws_apigatewayv2_deployment" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && local.is_http_api
  }

  api_id      = aws_apigatewayv2_api.this[each.key].id
  description = "Deployment for ${each.value.name} - ${var.environment} - Fingerprint: ${each.value.sha1}"

  triggers = {
    redeploy = each.value.sha1
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_deployment" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false
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

data "aws_api_gateway_vpc_link" "vpc_link" {
  count = try(var.aws_configuration.vpc_link_name, "") != "" ? 1 : 0
  name  = var.aws_configuration.vpc_link_name
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

resource "aws_apigatewayv2_stage" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && local.is_http_api
  }
  description   = "Stage for ${each.value.name} - ${var.environment}"
  api_id        = aws_apigatewayv2_api.this[each.key].id
  deployment_id = aws_apigatewayv2_deployment.this[each.key].id
  name          = local.deploy_stage_name
  stage_variables = merge(
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

data "aws_api_gateway_domain_name" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if try(v.domain_name, "") != ""
  }
  domain_name = each.value.domain_name
}

resource "aws_apigatewayv2_api_mapping" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false && try(v.domain_name, "") != ""
  }

  api_id          = local.is_http_api ? aws_apigatewayv2_api.this[each.key].id : aws_api_gateway_rest_api.this[each.key].id
  stage           = local.is_http_api ? aws_apigatewayv2_stage.this[each.key].name : aws_api_gateway_stage.this[each.key].stage_name
  domain_name     = data.aws_api_gateway_domain_name.this[each.key].id
  api_mapping_key = each.value.mapping
}

resource "aws_lambda_permission" "this" {
  for_each = merge([
    for api in local.all_apis : {
      for auth in api.authorizers : "${api.name}-${auth.name}" => {
        api_name  = api.name
        auth_name = auth.name
      } if auth.authtype == "lambda" && local.deploy_stage_only == false
    }
  ]...)
  action              = "lambda:InvokeFunction"
  principal           = "apigateway.amazonaws.com"
  source_arn          = local.is_http_api ? aws_apigatewayv2_stage.this[each.key].execution_arn : aws_api_gateway_stage.this[each.value.api_name].execution_arn
  function_name       = data.aws_lambda_function.lambda_authorizer[each.value.auth_name].arn
  statement_id_prefix = "${each.key}-"
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

data "aws_apigatewayv2_apis" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && local.is_http_api
  }
  protocol_type = "HTTP"
  name          = each.value.name
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

resource "aws_apigatewayv2_deployment" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && local.is_http_api
  }
  api_id      = data.aws_apigatewayv2_apis.staged[each.key].ids[0]
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

resource "aws_apigatewayv2_stage" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && local.is_http_api
  }
  description   = "Stage for ${each.value.name} - ${var.environment}"
  api_id        = data.aws_apigatewayv2_apis.staged[each.key].ids[0]
  deployment_id = aws_apigatewayv2_deployment.staged[each.key].id
  name          = local.deploy_stage_name
  stage_variables = merge(length(data.aws_api_gateway_vpc_link.vpc_link) > 0 ? {
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

resource "aws_apigatewayv2_api_mapping" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && try(v.domain_name, "") != ""
  }

  api_id          = local.is_http_api ? data.aws_apigatewayv2_apis.staged[each.key].id[0] : data.aws_api_gateway_rest_api.staged[each.key].id
  stage           = local.is_http_api ? aws_apigatewayv2_stage.staged[each.key].name : aws_api_gateway_stage.staged[each.key].stage_name
  domain_name     = data.aws_api_gateway_domain_name.this[each.key].id
  api_mapping_key = each.value.mapping
}

resource "aws_lambda_permission" "staged" {
  for_each = merge([
    for api in local.all_apis : {
      for auth in api.authorizers : "${api.name}-${auth.name}" => {
        api_name  = api.name
        auth_name = auth.name
      } if auth.authtype == "lambda" && local.deploy_stage_only == true
    }
  ]...)
  action              = "lambda:InvokeFunction"
  principal           = "apigateway.amazonaws.com"
  source_arn          = local.is_http_api ? aws_apigatewayv2_stage.this[each.key].execution_arn : aws_api_gateway_stage.this[each.value.api_name].execution_arn
  function_name       = data.aws_lambda_function.lambda_authorizer[each.value.auth_name].arn
  statement_id_prefix = "${each.key}-"
}
