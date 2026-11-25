##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#
# Plan-only tests: no cloud credentials are required.

mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/apigateway/test"
    }
  }
  mock_resource "aws_api_gateway_stage" {
    defaults = {
      arn           = "arn:aws:apigateway:us-east-1::/restapis/r1s2t3u4v5/stages/test"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:r1s2t3u4v5/test"
    }
  }
  mock_resource "aws_apigatewayv2_stage" {
    defaults = {
      arn           = "arn:aws:apigateway:us-east-1::/apis/a1b2c3d4e5/stages/test"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:a1b2c3d4e5/test"
    }
  }
  mock_data "aws_lambda_function" {
    defaults = {
      arn        = "arn:aws:lambda:us-east-1:123456789012:function:test"
      invoke_arn = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:test/invocations"
    }
  }
  mock_data "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test"
    }
  }
  mock_data "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/test/abcd"
    }
  }
  mock_data "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test/abcd"
    }
  }
  mock_data "aws_lb_listener" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/test/abcd/efgh"
    }
  }
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
  mock_data "aws_apigatewayv2_apis" {
    defaults = {
      ids = ["a1b2c3d4e5"]
    }
  }
  mock_data "aws_api_gateway_rest_api" {
    defaults = {
      id = "r1s2t3u4v5"
    }
  }
}

mock_provider "local" {}

variables {
  org = {
    organization_name = "acme"
    organization_unit = "payments"
    environment_type  = "nonprod"
    environment_name  = "dev"
  }
  environment   = "dev"
  absolute_path = "tests"
  api_files_dir = "apifiles"
  release = {
    name = "orders"
  }
}

run "rest_full_deploy_lambda" {
  command = plan

  variables {
    cloud_type = "lambda"
    apigw_definition = {
      name        = "orders"
      version     = "v1"
      file_name   = "orders"
      domain_name = "api.dev.example.com"
      mapping     = "orders"
    }
    aws_configuration = {
      stage = "dev"
      waf = {
        enabled = true
        name    = "orders-waf-dev"
      }
      settings = {
        logging_level   = "INFO"
        metrics_enabled = true
      }
      authorizers = [
        {
          name     = "Lambda-Auth"
          authtype = "lambda"
          type     = "request"
          lambda = {
            function  = "auth-dev"
            exec_role = "auth-dev-exec-role"
          }
        }
      ]
    }
  }

  assert {
    condition     = length(aws_api_gateway_rest_api.this) == 1 && length(aws_apigatewayv2_api.this) == 0
    error_message = "A REST API must be created when http_api is false."
  }
  assert {
    condition     = length(aws_wafv2_web_acl_association.waf) == 1 && length(data.aws_wafv2_web_acl.waf) == 1
    error_message = "The WAF must be looked up by name and associated when waf.enabled is true and no ARN is provided."
  }
  assert {
    condition     = length(aws_lambda_permission.this) == 1 && length(aws_lambda_permission.lambda_function) == 1
    error_message = "Lambda permissions must be created for the backend function and the authorizer."
  }
  assert {
    condition     = aws_cloudwatch_log_group.logging.name == "/aws/apigateway/dev/orders/v1"
    error_message = "Log group must follow {log_location}/{stage}/{name}/{version}."
  }
  assert {
    condition     = output.api_type == "REST" && output.custom_domain_url == "https://api.dev.example.com/orders"
    error_message = "Unexpected api_type or custom_domain_url output."
  }
}

run "rest_waf_by_arn" {
  command = plan

  variables {
    cloud_type = "ecs"
    apigw_definition = {
      name      = "orders"
      version   = "v1"
      file_name = "orders"
    }
    aws_configuration = {
      stage       = "dev"
      authorizers = []
      waf = {
        enabled = true
        arn     = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/orders/abcd"
      }
      custom_parameters = [
        { name = "lambdaEndpoint", value = "https://backend.internal" },
        { name = "lambdaFunctionExecRoleArn", value = "arn:aws:iam::123456789012:role/none" },
      ]
    }
  }

  assert {
    condition     = length(data.aws_wafv2_web_acl.waf) == 0 && aws_wafv2_web_acl_association.waf[0].web_acl_arn == "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/orders/abcd"
    error_message = "The provided WAF ARN must be used directly without a name lookup."
  }
}

run "rest_stage_only" {
  command = plan

  variables {
    cloud_type = "lambda"
    apigw_definition = {
      name        = "orders"
      version     = "v1"
      file_name   = "orders"
      domain_name = "api.dev.example.com"
      mapping     = "orders"
    }
    aws_configuration = {
      stage       = "qa"
      stage_only  = true
      authorizers = []
      settings = {
        logging_level = "ERROR"
      }
    }
  }

  assert {
    condition     = length(aws_api_gateway_rest_api.this) == 0 && length(aws_api_gateway_stage.staged) == 1
    error_message = "Stage-only mode must reuse the existing REST API and only create a stage."
  }
  assert {
    condition     = length(aws_api_gateway_method_settings.staged) == 1 && aws_api_gateway_method_settings.staged[0].rest_api_id == "r1s2t3u4v5"
    error_message = "Stage-only method settings must target the looked-up REST API."
  }
  assert {
    condition     = length(aws_apigatewayv2_api_mapping.staged) == 1 && aws_apigatewayv2_api_mapping.staged[0].api_id == "r1s2t3u4v5"
    error_message = "Stage-only domain mapping must target the looked-up REST API."
  }
}

run "http_full_deploy_vpc_link" {
  command = plan

  variables {
    cloud_type = "ecs"
    apigw_definition = {
      name      = "catalog"
      version   = "v1"
      file_name = "catalog"
      stage_variables = [
        { name = "STAGE", value = "dev" },
      ]
    }
    aws_configuration = {
      stage       = "dev"
      http_api    = true
      http_vpc_link = {
        id          = "vpcl-0123456789"
        type        = "lb"
        server_name = "catalog.internal"
        lb = {
          name          = "alb-catalog-dev"
          listener_port = 80
        }
      }
      cors = {
        allow_origins = ["https://app.example.com"]
      }
    }
  }

  assert {
    condition     = length(aws_apigatewayv2_api.this) == 1 && length(aws_api_gateway_rest_api.this) == 0
    error_message = "An HTTP API must be created when http_api is true."
  }
  assert {
    condition     = aws_apigatewayv2_stage.this[0].stage_variables["STAGE"] == "dev"
    error_message = "apigw_definition.stage_variables must be applied to the stage."
  }
  assert {
    condition     = length(aws_wafv2_web_acl_association.waf) == 0
    error_message = "WAF must never be associated with HTTP APIs."
  }
  assert {
    condition     = output.api_type == "HTTP" && output.custom_domain_url == null
    error_message = "Unexpected api_type or custom_domain_url output."
  }
}

run "http_stage_only" {
  command = plan

  variables {
    cloud_type = "eks"
    apigw_definition = {
      name        = "catalog"
      version     = "v1"
      file_name   = "catalog"
      domain_name = "api.dev.example.com"
      mapping     = "catalog"
    }
    aws_configuration = {
      stage       = "qa"
      stage_only  = true
      http_api    = true
      custom_parameters = [
        { name = "elb", value = { endpoint = "http://catalog.internal" } },
      ]
    }
  }

  assert {
    condition     = length(aws_apigatewayv2_api.this) == 0 && length(aws_apigatewayv2_stage.staged) == 1
    error_message = "Stage-only mode must reuse the existing HTTP API and only create a stage."
  }
  assert {
    condition     = length(aws_api_gateway_deployment.staged) == 0
    error_message = "No REST deployment may be planned for an HTTP stage-only deployment."
  }
  assert {
    condition     = aws_apigatewayv2_api_mapping.staged[0].api_id == "a1b2c3d4e5"
    error_message = "Stage-only domain mapping must target the looked-up HTTP API."
  }
}
