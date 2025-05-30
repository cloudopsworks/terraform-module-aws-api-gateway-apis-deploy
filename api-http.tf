##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#


#################################################################
# Deploy api only if deploy_stage_only is false                 #
#################################################################
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

data "aws_api_gateway_vpc_link" "vpc_link" {
  count = try(var.aws_configuration.vpc_link_name, "") != "" ? 1 : 0
  name  = var.aws_configuration.vpc_link_name
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

#################################################################
# Deploy only stage as deploy_stage_only is true                #
#################################################################
data "aws_apigatewayv2_apis" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && local.is_http_api
  }
  protocol_type = "HTTP"
  name          = each.value.name
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

resource "aws_apigatewayv2_api_mapping" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true && try(v.domain_name, "") != ""
  }

  api_id          = local.is_http_api ? data.aws_apigatewayv2_apis.staged[each.key].id[0] : data.aws_api_gateway_rest_api.staged[each.key].id
  stage           = local.is_http_api ? aws_apigatewayv2_stage.staged[each.key].name : aws_api_gateway_stage.staged[each.key].stage_name
  domain_name     = data.aws_api_gateway_domain_name.this[each.key].id
  api_mapping_key = each.value.mapping
}
