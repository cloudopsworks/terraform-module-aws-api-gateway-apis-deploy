##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

# AWS API Gateway HTTP API VPC Link
data "aws_apigatewayv2_vpc_link" "vpc_link" {
  count       = try(var.aws_configuration.http_vpc_link.id, "") != "" ? 1 : 0
  vpc_link_id = var.aws_configuration.http_vpc_link.id
}

# VPC Link type: ELB
data "aws_lb" "vpc_link" {
  count = try(var.aws_configuration.http_vpc_link.type, "") == "lb" ? 1 : 0
  name  = var.aws_configuration.http_vpc_link.lb.name
}

data "aws_lb_listener" "vpc_link" {
  count             = try(var.aws_configuration.http_vpc_link.type, "") == "lb" ? 1 : 0
  load_balancer_arn = data.aws_lb.vpc_link[0].arn
  port              = var.aws_configuration.http_vpc_link.lb.listener_port
}

#################################################################
# Deploy api only if deploy_stage_only is false                 #
#################################################################
resource "aws_apigatewayv2_api" "this" {
  count                        = local.deploy_stage_only == false && local.is_http_api ? 1 : 0
  name                         = var.apigw_definition.name
  version                      = var.apigw_definition.version
  description                  = format("API Gateway HTTP API for %s - Version: %s - Environment: %s,\n%s", var.apigw_definition.name, var.apigw_definition.version, var.environment, try(local.final_content, ""))
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = (!try(var.aws_configuration.enable_execute_api_endpoint, false))
  body                         = jsonencode(local.final_content)
  fail_on_warnings             = try(var.aws_configuration.fail_on_warnings, true)
  cors_configuration {
    allow_credentials = try(var.aws_configuration.cors.allow_credentials, false)
    allow_headers     = try(var.aws_configuration.cors.allow_headers, [])
    allow_methods     = try(var.aws_configuration.cors.allow_methods, ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
    allow_origins     = try(var.aws_configuration.cors.allow_origins, ["*"])
    expose_headers    = try(var.aws_configuration.cors.expose_headers, [])
    max_age           = try(var.aws_configuration.cors.max_age, null)
  }
  tags = local.all_tags
}

resource "aws_apigatewayv2_deployment" "this" {
  count       = local.deploy_stage_only == false && local.is_http_api ? 1 : 0
  api_id      = aws_apigatewayv2_api.this[0].id
  description = "Deployment for ${var.apigw_definition.name} - ${var.environment} - Fingerprint: ${local.sha1}"
  triggers = {
    redeploy = local.sha1
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "this" {
  count         = local.deploy_stage_only == false && local.is_http_api ? 1 : 0
  description   = "Stage for ${var.apigw_definition.name} - ${var.environment}"
  api_id        = aws_apigatewayv2_api.this[0].id
  deployment_id = aws_apigatewayv2_deployment.this[0].id
  name          = local.deploy_stage_name
  stage_variables = merge(
    length(data.aws_apigatewayv2_vpc_link.vpc_link) > 0 ? {
      vpc_link = data.aws_apigatewayv2_vpc_link.vpc_link[0].id
    } : {},
    local.is_lambda ? {
      lambdaEndpoint = data.aws_lambda_function.lambda_function[0].invoke_arn
    } : {},
    {
      for item in try(var.apigw_definition.stage_variables, {}) :
      item.name => item.value
    },
    {
      for item in try(var.aws_configuration.stage_variables, {}) :
      item.name => item.value
    }
  )
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logging.arn
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
  count         = local.deploy_stage_only == true && local.is_http_api ? 1 : 0
  protocol_type = "HTTP"
  name          = var.apigw_definition.name
}

resource "aws_apigatewayv2_deployment" "staged" {
  count       = local.deploy_stage_only == true && local.is_http_api ? 1 : 0
  api_id      = tolist(data.aws_apigatewayv2_apis.staged[0].ids)[0]
  description = "Deployment for ${var.apigw_definition.name} - ${var.environment} - Fingerprint: ${local.sha1}"
  triggers = {
    redeploy = local.sha1
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "staged" {
  count         = local.deploy_stage_only == true && local.is_http_api ? 1 : 0
  description   = "Stage for ${var.apigw_definition.name} - ${var.environment}"
  api_id        = tolist(data.aws_apigatewayv2_apis.staged[0].ids)[0]
  deployment_id = aws_apigatewayv2_deployment.staged[0].id
  name          = local.deploy_stage_name
  stage_variables = merge(length(data.aws_apigatewayv2_vpc_link.vpc_link) > 0 ? {
    vpc_link = data.aws_apigatewayv2_vpc_link.vpc_link[0].id
    } : {},
    {
      for item in try(var.apigw_definition.stage_variables, {}) :
      item.name => item.value
    },
    {
      for item in try(var.aws_configuration.stage_variables, {}) :
      item.name => item.value
    }
  )

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logging.arn
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
  count           = local.deploy_stage_only == true && try(var.apigw_definition.domain_name, "") != "" ? 1 : 0
  api_id          = local.is_http_api ? tolist(data.aws_apigatewayv2_apis.staged[0].id)[0] : data.aws_api_gateway_rest_api.staged[0].id
  stage           = local.is_http_api ? aws_apigatewayv2_stage.staged[0].name : aws_api_gateway_stage.staged[0].stage_name
  domain_name     = data.aws_api_gateway_domain_name.this[0].id
  api_mapping_key = var.apigw_definition.mapping
}
