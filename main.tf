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
  source_arn          = local.is_http_api ? aws_apigatewayv2_stage.this[each.value.api_name].execution_arn : aws_api_gateway_stage.this[each.value.api_name].execution_arn
  function_name       = data.aws_lambda_function.lambda_authorizer[each.value.auth_name].arn
  statement_id_prefix = "${each.key}-"
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
  source_arn          = local.is_http_api ? aws_apigatewayv2_stage.this[each.value.api_name].execution_arn : aws_api_gateway_stage.this[each.value.api_name].execution_arn
  function_name       = data.aws_lambda_function.lambda_authorizer[each.value.auth_name].arn
  statement_id_prefix = "${each.key}-"
}
