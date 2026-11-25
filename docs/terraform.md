## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.74.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.1 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.10 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_api_gateway_deployment.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_method_settings.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_apigatewayv2_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_api_mapping.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_api_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_deployment.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_deployment) | resource |
| [aws_apigatewayv2_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_deployment) | resource |
| [aws_apigatewayv2_stage.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_apigatewayv2_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudwatch_log_group.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_permission.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_object.publish_bucket_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_wafv2_web_acl_association.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [local_file.final_content_json](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.final_content_yaml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_domain_name) | data source |
| [aws_api_gateway_rest_api.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_rest_api) | data source |
| [aws_api_gateway_vpc_link.vpc_link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_vpc_link) | data source |
| [aws_apigatewayv2_apis.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/apigatewayv2_apis) | data source |
| [aws_apigatewayv2_vpc_link.vpc_link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/apigatewayv2_vpc_link) | data source |
| [aws_iam_role.lambda_auth_exec_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.lambda_function_exec_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_lambda_function.lambda_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_lb.vpc_link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_lb_listener.vpc_link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.publish_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_wafv2_web_acl.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/wafv2_web_acl) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_absolute_path"></a> [absolute\_path](#input\_absolute\_path) | (Optional) Base directory used to resolve api\_files\_dir. Set it to the deployment directory (get\_terragrunt\_dir() in Terragrunt). Default: ".". | `string` | `"."` | no |
| <a name="input_api_files_dir"></a> [api\_files\_dir](#input\_api\_files\_dir) | (Optional) Directory, relative to absolute\_path, that holds the OpenAPI/Swagger files. Default: "apifiles/". | `string` | `"apifiles/"` | no |
| <a name="input_apigw_definition"></a> [apigw\_definition](#input\_apigw\_definition) | (Required) API Gateway definition: name, version, spec file name, optional custom domain mapping and stage variables. See the inline YAML documentation. Default: {}. | `any` | `{}` | no |
| <a name="input_aws_configuration"></a> [aws\_configuration](#input\_aws\_configuration) | (Required) API Gateway deployment options: stage, API type, endpoint, VPC links, logging, CORS, WAF, stage settings, authorizers and template parameters. aws\_configuration.stage is mandatory. See the inline YAML documentation for every key. Default: {}. | `any` | `{}` | no |
| <a name="input_cloud_type"></a> [cloud\_type](#input\_cloud\_type) | (Required) Backend runtime type. Valid values: lambda, beanstalk, eks, kubernetes, ecs. lambda enables the backend Lambda lookup, invoke permission and Lambda template variables. | `string` | n/a | yes |
| <a name="input_debug"></a> [debug](#input\_debug) | (Optional) Write the final rendered spec to <api\_files\_dir>/<file\_name>\_final.json and \_final.yaml for inspection. Default: false. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | (Required) Deployment environment name (e.g. dev, qa, prod). Used in resource descriptions and to resolve Lambda function and role names. | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Is this a hub or spoke configuration? | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | Organization details | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_release"></a> [release](#input\_release) | (Optional) Release information (name, source). release.name resolves the backend Lambda function and execution role when cloud\_type is lambda. Default: {}. | `any` | `{}` | no |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | Spoke ID Number, must be a 3 digit number | `string` | `"001"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_definition_fingerprint"></a> [api\_definition\_fingerprint](#output\_api\_definition\_fingerprint) | SHA1 of the source OpenAPI file. A change in this value triggers a new deployment. |
| <a name="output_api_endpoint"></a> [api\_endpoint](#output\_api\_endpoint) | Default execute-api endpoint of the HTTP API. Null for REST APIs and for stage-only deployments. |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | ID of the API Gateway API that received the deployment (created by the module, or looked up when stage\_only is true). |
| <a name="output_api_type"></a> [api\_type](#output\_api\_type) | API Gateway flavour deployed by this module: HTTP (API Gateway v2) or REST (API Gateway v1). |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch Log Group that receives the stage access logs. |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch Log Group that receives the stage access logs. |
| <a name="output_custom_domain_url"></a> [custom\_domain\_url](#output\_custom\_domain\_url) | Base URL of the API on its custom domain (https://<domain\_name>/<mapping>). Null when no domain\_name is configured. |
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | ID of the API Gateway deployment attached to the stage. |
| <a name="output_published_spec_s3_uri"></a> [published\_spec\_s3\_uri](#output\_published\_spec\_s3\_uri) | S3 URI of the published API specification backup. Null when publish\_bucket is disabled. |
| <a name="output_stage_arn"></a> [stage\_arn](#output\_stage\_arn) | ARN of the deployed API Gateway stage. |
| <a name="output_stage_execution_arn"></a> [stage\_execution\_arn](#output\_stage\_execution\_arn) | Execution ARN of the deployed stage, usable as source\_arn in Lambda permissions. |
| <a name="output_stage_invoke_url"></a> [stage\_invoke\_url](#output\_stage\_invoke\_url) | Invoke URL of the deployed stage on the default execute-api endpoint. |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | Name of the deployed API Gateway stage. |
