##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

locals {
  deploy_stage_name          = var.aws_configuration.stage
  deploy_stage_only          = try(var.aws_configuration.stage_only, false)
  config_endpoint_type       = try(var.aws_configuration.endpoint_type, "REGIONAL")
  default_log_location       = try(var.aws_configuration.log_location, "/aws/apigateway")
  default_log_retention_days = try(var.aws_configuration.log_retention_days, 30)
  is_lambda                  = (var.cloud_type == "lambda")
  release_name               = try(var.release.name, "default")
  is_http_api                = try(var.aws_configuration.http_api, false)

  content_parameters = merge({
    for k, v in data.aws_lambda_function.lambda_authorizer : k => {
      authorizer_uri         = v.invoke_arn
      authorizer_credentials = data.aws_iam_role.lambda_exec_role[k].arn
    }
    },
    local.is_lambda ? {
      lambdaEndpoint     = data.aws_lambda_function.lambda_function[0].invoke_arn
      lambdaFunctionName = data.aws_lambda_function.lambda_function[0].function_name
  } : {})
  content = (fileexists("${var.absolute_path}/${var.api_files_dir}/${var.apigw_definition.file_name}.json") ?
    jsondecode(templatefile("${var.absolute_path}/${var.api_files_dir}/${var.apigw_definition.file_name}.json", local.content_parameters)) :
  yamldecode(templatefile("${var.absolute_path}/${var.api_files_dir}/${var.apigw_definition.file_name}.yaml", local.content_parameters)))
  sha1 = filesha1(
    fileexists("${var.absolute_path}/${var.api_files_dir}/${var.apigw_definition.file_name}.json") ?
    "${var.absolute_path}/${var.api_files_dir}/${var.apigw_definition.file_name}.json" :
    "${var.absolute_path}/${var.api_files_dir}/${var.apigw_definition.file_name}.yaml"
  )

  #
  # FIXME: The components will be not used in the current code, so they are commented out.
  components = merge(
    {
      for cname, cvalue in local.content.components : cname => cvalue
      if cname != "securitySchemes"
    },
    {
      "securitySchemes" = {
        for auth in var.aws_configuration.authorizers : auth.name => {
          name                           = try(auth.scheme.name, "Authorization")
          type                           = try(auth.scheme.type, "apiKey")
          in                             = try(auth.scheme.in, "header")
          "x-amazon-apigateway-authtype" = try(auth.scheme.authtype, "custom")
          "x-amazon-apigateway-authorizer" = {
            authorizerUri                  = data.aws_lambda_function.lambda_authorizer[auth.name].invoke_arn
            identitySource                 = try(auth.identity_source, "$request.header.Authorization")
            authorizerCredentials          = data.aws_iam_role.lambda_exec_role[auth.name].arn
            authorizerResultTtlInSeconds   = try(auth.result_ttl_seconds, 0)
            authorizerPayloadFormatVersion = try(auth.payload_format_version, "2.0")
            enableSimpleResponses          = try(auth.enable_simple_responses, false)
            type                           = upper(try(auth.type, "request"))
          }
        } if auth.authtype == "lambda"
      }
    }
  )

  final_content = merge(local.content,
    {
      components = local.components
    }
  )
}

#################################################################
# Lambda Function call catalogue                                #
#################################################################
data "aws_lambda_function" "lambda_function" {
  count         = local.is_lambda ? 1 : 0
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

data "aws_api_gateway_domain_name" "this" {
  count       = try(var.apigw_definition.domain_name, "") != "" ? 1 : 0
  domain_name = var.apigw_definition.domain_name
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count           = local.deploy_stage_only == false && try(var.apigw_definition.domain_name, "") != "" ? 1 : 0
  api_id          = local.is_http_api ? aws_apigatewayv2_api.this[0].id : aws_api_gateway_rest_api.this[0].id
  stage           = local.is_http_api ? aws_apigatewayv2_stage.this[0].name : aws_api_gateway_stage.this[0].stage_name
  domain_name     = data.aws_api_gateway_domain_name.this[0].id
  api_mapping_key = var.apigw_definition.mapping
}

resource "aws_lambda_permission" "this" {
  for_each = {
    for auth in var.aws_configuration.authorizers : auth.name => {
      auth_name = auth.name
    } if auth.authtype == "lambda" && local.deploy_stage_only == false
  }
  action              = "lambda:InvokeFunction"
  principal           = "apigateway.amazonaws.com"
  source_arn          = local.is_http_api ? aws_apigatewayv2_stage.this[0].execution_arn : aws_api_gateway_stage.this[0].execution_arn
  function_name       = data.aws_lambda_function.lambda_authorizer[each.key].arn
  statement_id_prefix = format("%s-%s", each.key, var.apigw_definition.name)
}

resource "aws_lambda_permission" "staged" {
  for_each = {
    for auth in var.aws_configuration.authorizers : auth.name => {
      auth_name = auth.name
    } if auth.authtype == "lambda" && local.deploy_stage_only == true
  }
  action              = "lambda:InvokeFunction"
  principal           = "apigateway.amazonaws.com"
  source_arn          = local.is_http_api ? aws_apigatewayv2_stage.this[0].execution_arn : aws_api_gateway_stage.this[0].execution_arn
  function_name       = data.aws_lambda_function.lambda_authorizer[each.key].arn
  statement_id_prefix = format("%s-%s", each.key, var.apigw_definition.name)
}
