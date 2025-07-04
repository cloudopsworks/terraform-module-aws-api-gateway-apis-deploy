##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

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
#  http_api: false
#  endpoint_type: REGIONAL
#  vpc_endpoint_ids:
#   - vpce-1234567890abcdef0
#   - vpce-1234567890abcdef1
#  disable_execute_api_endpoint: false
#  minimum_compression_size: null
#  xray_enabled: true
#  cache_cluster_enabled: true
#  cache_cluster_size: 0.5
#  vpc_link_name: test-link-dev # DEPRECATED
#  rest_vpc_link_name: test-link-dev # Replaces: vpc_link_name
#  http_vpc_link_id: test-http-link-dev
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

# Documentation:
# name: test
# version: v2
# mapping: test-apis/api/2.0
# domain_name: apigw-dev.sample.com
# file_name: test
# stage_variables:  # comment out if not needed
#   - name: api_variable
#     value: api_value
variable "apigw_definition" {
  description = "API Gateway definitions for the api."
  type        = any
  default     = {}
}

variable "absolute_path" {
  description = "Absolute path to the terragrunt directory."
  type        = string
  default     = "."
}

# Variable to hold release information, such as name and version.
# from release.yaml
# Example:
# release:
#   name: release_name
#   source:
#     name: source_name
#     version: version_number
variable "release" {
  description = "Release information for the API Gateway deployment."
  type        = any
  default     = {}
}

variable "cloud_type" {
  description = "Type of cloud provider for the deployment."
  type        = string
  validation {
    condition     = length(regexall("lambda|beanstalk|eks|kubernetes|ecs", var.cloud_type)) > 0
    error_message = "Only AWS types (lambda, beanstalk, eks, kubernetes, ecs) are supported as cloud type"
  }
}

variable "debug" {
  description = "Enable debug mode to output final content in JSON and YAML formats."
  type        = bool
  default     = false
}