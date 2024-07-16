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
#    apisource: test
#  - name: test2
#    version: v2
#    apisource: test2
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
#  vpc_link_name: test-link-dev
#  log_location: /aws/apigateway
#  log_retention_days: 30
#  stage_variables:
#    - name: url
#      value: test-api.dev.sample.com
#  authorizers:
#    - name: Lambda-Auth
#      authtype: lambda
#      lambda:
#        uri: 'arn:aws:lambda:us-east-1:12345678912:function:lambda-auth-dev-lambda-exec-role'
#        exec_role: lambda-auth-dev-lambda-exec-role
variable "aws_configuration" {
  description = "AWS configuration to deploy the api gateway."
  type        = any
  default     = {}
}

# API Gateway definitions for each api, follows the below format:
#  - name: test
#    version: v2
#    mapping: test-apis/api/2.0
#    domain_name: apigw-dev.sample.com
#  - name: test2
#    version: v2
#    mapping: test2-apis/api/2.0
#    domain_name: apigw-dev.sample.com
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

