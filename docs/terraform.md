## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.72.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.9 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_deployment.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_method_settings.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_method_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_apigatewayv2_api_mapping.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_api_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_cloudwatch_log_group.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_permission.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_object.publish_bucket_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_api_gateway_domain_name.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_domain_name) | data source |
| [aws_api_gateway_rest_api.staged](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_rest_api) | data source |
| [aws_api_gateway_vpc_link.vpc_link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/api_gateway_vpc_link) | data source |
| [aws_iam_role.lambda_exec_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_lambda_function.lambda_authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.publish_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_absolute_path"></a> [absolute\_path](#input\_absolute\_path) | Absolute path to the terragrunt directory. | `string` | `"."` | no |
| <a name="input_api_files_dir"></a> [api\_files\_dir](#input\_api\_files\_dir) | Directory where api files are stored | `string` | `"apifiles/"` | no |
| <a name="input_apigw_definitions"></a> [apigw\_definitions](#input\_apigw\_definitions) | API Gateway definitions for each api. | `any` | `[]` | no |
| <a name="input_apis"></a> [apis](#input\_apis) | List of apis to deploy into api gateway. | `any` | `[]` | no |
| <a name="input_aws_configuration"></a> [aws\_configuration](#input\_aws\_configuration) | AWS configuration to deploy the api gateway. | `any` | `{}` | no |
| <a name="input_cloud_provider"></a> [cloud\_provider](#input\_cloud\_provider) | Provider indicator in order to perform deployment | `string` | `"aws"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment to deploy the api gateway | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Establish this is a HUB or spoke configuration | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | n/a | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | n/a | `string` | `"001"` | no |

## Outputs

No outputs.
