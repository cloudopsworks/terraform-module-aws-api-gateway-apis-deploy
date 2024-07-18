##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

variable "cloud_provider" {
  description = "Provider indicator in order to perform deployment"
  type        = string
  default     = "aws"
  validation {
    condition     = var.cloud_provider == "aws"
    error_message = "Only AWS is supported as cloud provider"
  }
}

# List of apis to deploy into api gateway, follows the below format:
#  - name: test
#    version: v2
#  - name: test2
#    version: v2
variable "apis" {
  description = "List of apis to deploy into api gateway."
  type        = any
  default     = []
}

variable "api_files_dir" {
  description = "Directory where api files are stored"
  type        = string
  default     = "apifiles/"
}

variable "environment" {
  description = "Environment to deploy the api gateway"
  type        = string
}

# AWS configuration to deploy the api gateway with below format:
#  stage: dev
#  stage_only: true
#  endpoint_type: REGIONAL
#  vpc_endpoint_ids:
#   - vpce-1234567890abcdef0
#   - vpce-1234567890abcdef1
#  disable_execute_api_endpoint: false
#  minimum_compression_size: null
#  xray_enabled: true
#  cache_cluster_enabled: true
#  cache_cluster_size: 0.5
#  vpc_link_name: test-link-dev
#  log_location: /aws/apigateway
#  log_retention_days: 30
#  stage_variables:
#    - name: url
#      value: test-api.dev.sample.com
#  authorizers:
#    - name: Lambda-Auth
#      authtype: lambda
#      result_ttl_seconds: 10
#      identity_source: method.request.header.Authorization
#      type: request
#      lambda:
#        function: lambda-auth-dev
#        exec_role: lambda-auth-dev-lambda-exec-role
variable "aws_configuration" {
  description = "AWS configuration to deploy the api gateway."
  type        = any
  default     = {}
}

# API Gateway definitions for each api, follows the below format,
#  note the second api does not has stage_variables defined because is optional:
#  - name: test
#    version: v2
#    mapping: test-apis/api/2.0
#    domain_name: apigw-dev.sample.com
#    file_name: test
#    stage_variables:
#      - name: variable_name
#        value: variable_value
#  - name: test2
#    version: v2
#    mapping: test2-apis/api/2.0
#    domain_name: apigw-dev.sample.com
#    file_name: test
#
variable "apigw_definitions" {
  description = "API Gateway definitions for each api."
  type        = any
  default     = []
}


variable "absolute_path" {
  description = "Absolute path to the terragrunt directory."
  type        = string
  default     = "."
}

