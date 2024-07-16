##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  all_apis_list = [
    for api in var.apis : {
      for def in var.apigw_definitions : api.name => {
        name            = api.name
        version         = api.version
        mapping         = def.mapping
        domain_name     = def.domain_name
        stage_variables = try(var.aws_configuration.stage_variables, [])
        json_content    = file("${var.absolute_path}/${var.api_files_dir}/${api.apisource}.json")
        sha1            = filesha1("${var.absolute_path}/${var.api_files_dir}/${api.apisource}.json")
      }
    }
  ]
  all_apis                   = merge(local.all_apis_list...)
  deploy_stage_name          = var.aws_configuration.stage
  deploy_stage_only          = try(var.aws_configuration.stage_only, false)
  config_endpoint_type       = try(var.aws_configuration.endpoint_type, "REGIONAL")
  default_log_location       = try(var.aws_configuration.log_location, "/aws/apigateway")
  default_log_retention_days = try(var.aws_configuration.log_retention_days, 30)
}

#################################################################
# Deploy api only if deploy_stage_only is false                 #
#################################################################
resource "aws_api_gateway_rest_api" "this" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false
  }

  name                         = each.value.name
  body                         = each.value.json_content
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
    for k, v in local.all_apis : k => v if local.deploy_stage_only == false
  }
  deployment_id = aws_api_gateway_deployment.this[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.this[each.key].id
  stage_name    = local.deploy_stage_name
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


#################################################################
# Deploy only stage as deploy_stage_only is true                #
#################################################################
data "aws_api_gateway_rest_api" "staged" {
  for_each = {
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true
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
    for k, v in local.all_apis : k => v if local.deploy_stage_only == true
  }
  deployment_id = aws_api_gateway_deployment.staged[each.key].id
  rest_api_id   = data.aws_api_gateway_rest_api.staged[each.key].id
  stage_name    = local.deploy_stage_name
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
