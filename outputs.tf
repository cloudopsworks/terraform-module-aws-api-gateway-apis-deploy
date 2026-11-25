##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "api_type" {
  description = "API Gateway flavour deployed by this module: HTTP (API Gateway v2) or REST (API Gateway v1)."
  value       = local.is_http_api ? "HTTP" : "REST"
}

output "api_id" {
  description = "ID of the API Gateway API that received the deployment (created by the module, or looked up when stage_only is true)."
  value       = try(local.http_stage.api_id, local.rest_stage.rest_api_id, null)
}

output "api_endpoint" {
  description = "Default execute-api endpoint of the HTTP API. Null for REST APIs and for stage-only deployments."
  value       = try(aws_apigatewayv2_api.this[0].api_endpoint, null)
}

output "stage_name" {
  description = "Name of the deployed API Gateway stage."
  value       = try(local.http_stage.name, local.rest_stage.stage_name, null)
}

output "stage_arn" {
  description = "ARN of the deployed API Gateway stage."
  value       = try(local.http_stage.arn, local.rest_stage.arn, null)
}

output "stage_invoke_url" {
  description = "Invoke URL of the deployed stage on the default execute-api endpoint."
  value       = try(local.http_stage.invoke_url, local.rest_stage.invoke_url, null)
}

output "stage_execution_arn" {
  description = "Execution ARN of the deployed stage, usable as source_arn in Lambda permissions."
  value       = local.stage_execution_arn
}

output "deployment_id" {
  description = "ID of the API Gateway deployment attached to the stage."
  value       = try(local.http_stage.deployment_id, local.rest_stage.deployment_id, null)
}

output "api_definition_fingerprint" {
  description = "SHA1 of the source OpenAPI file. A change in this value triggers a new deployment."
  value       = local.sha1
}

output "custom_domain_url" {
  description = "Base URL of the API on its custom domain (https://<domain_name>/<mapping>). Null when no domain_name is configured."
  value       = try(var.apigw_definition.domain_name, "") != "" ? format("https://%s/%s", var.apigw_definition.domain_name, try(var.apigw_definition.mapping, "")) : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group that receives the stage access logs."
  value       = aws_cloudwatch_log_group.logging.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group that receives the stage access logs."
  value       = aws_cloudwatch_log_group.logging.arn
}

output "published_spec_s3_uri" {
  description = "S3 URI of the published API specification backup. Null when publish_bucket is disabled."
  value       = try(format("s3://%s/%s", aws_s3_object.publish_bucket_api[0].bucket, aws_s3_object.publish_bucket_api[0].key), null)
}
