##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# api_files_dir: "apifiles/" # (Optional) Directory, relative to absolute_path, holding the OpenAPI files. Default: "apifiles/"
variable "api_files_dir" {
  description = "(Optional) Directory, relative to absolute_path, that holds the OpenAPI/Swagger files. Default: \"apifiles/\"."
  type        = string
  default     = "apifiles/"
}

# environment: "dev" # (Required) Deployment environment. Used in descriptions and in the Lambda lookup names "<release.name>-<environment>".
variable "environment" {
  description = "(Required) Deployment environment name (e.g. dev, qa, prod). Used in resource descriptions and to resolve Lambda function and role names."
  type        = string
}

# aws_configuration:                   # (Required) Deployment options for the API Gateway.
#   stage: "dev"                       # (Required) Stage name to deploy.
#   stage_only: false                  # (Optional) true = only deploy a new stage on an API that already exists (looked up by apigw_definition.name). Stage-only stages skip xray_enabled, cache_cluster_size, the "lambdaEndpoint" stage variable and HTTP settings. Default: false
#   http_api: false                    # (Optional) true = HTTP API (API Gateway v2), false = REST API (API Gateway v1). Default: false
#   endpoint_type: "REGIONAL"          # (Optional) REST only. Valid values: "REGIONAL", "EDGE", "PRIVATE". Default: "REGIONAL"
#   vpc_endpoint_ids:                  # (Optional) REST only, used with endpoint_type = "PRIVATE". Default: null
#     - "vpce-1234567890abcdef0"
#   put_rest_api_mode: "overwrite"     # (Optional) REST only, honored for PRIVATE endpoints. Valid values: "overwrite", "merge". Default: "overwrite"
#   disable_execute_api_endpoint: true # (Optional) REST only. Disable the default execute-api endpoint. Default: true
#   enable_execute_api_endpoint: false # (Optional) HTTP only. Enable the default execute-api endpoint. Default: false
#   minimum_compression_size: null     # (Optional) REST only. Payload compression threshold in bytes, -1 to 10485760. Default: null (disabled)
#   client_certificate_id: ""          # (Optional) REST only. API Gateway client certificate ID for backend mTLS. Default: null
#   xray_enabled: false                # (Optional) REST only. Enable X-Ray tracing on the stage. Default: null (provider default)
#   cache_cluster_enabled: false       # (Optional) REST only. Enable the stage cache cluster. Default: null (false)
#   cache_cluster_size: "0.5"          # (Optional) REST only. Cache size in GB. Valid values: "0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237". Default: null
#   rest_vpc_link_name: ""             # (Optional) REST only. Existing VPC Link name; its ID is exposed as stage variable "vpc_link". Default: ""
#   vpc_link_name: ""                  # (Optional) DEPRECATED, use rest_vpc_link_name. Takes precedence when both are set.
#   http_vpc_link:                     # (Optional) HTTP only. VPC Link integration settings. Default: {}
#     id: "abcde1"                     # (Optional) Existing HTTP API VPC Link ID; exposed as stage variable "vpc_link".
#     type: "lb"                       # (Optional) Valid values: "lb", "cloudmap". Only "lb" triggers module-side lookups: it resolves the listener ARN into the ${elb.endpoint} template variable.
#     server_name: "svc.internal"      # (Required when type = "lb") TLS server name, exposed as ${elb.server_name}.
#     lb:                              # (Required when type = "lb") Load balancer lookup.
#       name: "alb-svc-dev"            # (Required) Load balancer name.
#       listener_port: 80              # (Required) Listener port.
#   fail_on_warnings: true             # (Optional) Fail the import when the OpenAPI definition raises warnings. Default: true
#   log_location: "/aws/apigateway"    # (Optional) Access-log group prefix; the group is "<log_location>/<stage>/<name>/<version>". Default: "/aws/apigateway"
#   log_retention_days: 30             # (Optional) Access-log retention in days. Default: 30
#   cors:                              # (Optional) HTTP only. CORS configuration. Default: allow all origins with GET, POST, PUT, DELETE, OPTIONS
#     allow_credentials: false         # (Optional) Default: false
#     allow_headers: []                # (Optional) Default: []
#     allow_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"] # (Optional) Default as shown
#     allow_origins: ["*"]             # (Optional) Default: ["*"]
#     expose_headers: []               # (Optional) Default: []
#     max_age: 300                     # (Optional) Preflight cache in seconds. Default: null
#   waf:                               # (Optional) REST only. WAFv2 web ACL association. Default: disabled
#     enabled: false                   # (Optional) Associate a web ACL with the stage. Default: false
#     arn: ""                          # (Optional) Web ACL ARN. When set, no lookup is performed.
#     name: ""                         # (Required when arn is empty) Web ACL name to look up.
#     scope: "REGIONAL"                # (Optional) Lookup scope. API Gateway stages accept "REGIONAL" web ACLs only. Default: "REGIONAL"
#   settings:                          # (Optional) Stage settings. REST: applied to all methods ("*/*"). HTTP: default route settings (full deployments only). Default: {}
#     logging_level: "ERROR"           # (Optional) Valid values: "OFF", "ERROR", "INFO". REST default: "ERROR". HTTP: not sent unless set (AWS supports execution logs on REST and WebSocket APIs only)
#     metrics_enabled: false           # (Optional) REST only. CloudWatch metrics. Default: null
#     detailed_metrics_enabled: false  # (Optional) HTTP only. Detailed route metrics. Default: null
#     data_trace_enabled: false        # (Optional) Full request/response logging. Default: null
#     throttling_burst_limit: 5000     # (Optional) Burst limit, -1 to disable. Default: null (account limit)
#     throttling_rate_limit: 10000     # (Optional) Steady-state requests per second, -1 to disable. Default: null (account limit)
#     caching_enabled: false           # (Optional) REST only. Requires cache_cluster_enabled. Default: null
#     cache_ttl_in_seconds: 300        # (Optional) REST only. 0 to 3600. Default: null (300)
#     cache_data_encrypted: false      # (Optional) REST only. Default: null
#     require_authorization_for_cache_control: true # (Optional) REST only. Default: null
#     unauthorized_cache_control_header_strategy: "SUCCEED_WITH_RESPONSE_HEADER" # (Optional) REST only. Valid values: "FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER". Default: null
#   publish_bucket:                    # (Optional) Back up the templated spec (before authorizer/integration injection) as YAML to an existing S3 bucket. Default: disabled
#     enabled: false                   # (Optional) Default: false
#     name: "apigw-backup"             # (Required when enabled) Bucket name.
#     prefix_path: "apis"              # (Optional) Key prefix; the object is "<prefix_path>/<apigw_definition.name>.yaml". Set it: an empty prefix yields a key with a leading "/". Default: ""
#   custom_parameters:                 # (Optional) Extra template variables for the OpenAPI file, referenced as ${<name>}. Default: []
#     - name: "backend_url"            # (Required) Variable name; must be a valid identifier.
#       value: "https://svc.internal"  # (Required) Value; strings, numbers, lists and maps are accepted.
#   stage_variables:                   # (Optional) Stage variables applied after apigw_definition.stage_variables (same names override). Default: []
#     - name: "backend_host"           # (Required) Stage variable name.
#       value: "svc.internal"          # (Required) Stage variable value.
#   lambda_options:                    # (Optional) HTTP + cloud_type "lambda" only. Shared "lambda_integration" injected into the spec. Default: {}
#     format_version: "2.0"            # (Optional) Payload format version. Valid values: "1.0", "2.0". Default: "2.0"
#     responses: {}                    # (Optional) Integration responses map. Default: {}
#     pass_through_behavior: "when_no_match" # (Optional) Valid values: "when_no_match", "when_no_templates", "never". Default: "when_no_match"
#     timeout_millis: 30000            # (Optional) Integration timeout in milliseconds. Default: 30000
#     content_handling: "CONVERT_TO_TEXT" # (Optional) Valid values: "CONVERT_TO_TEXT", "CONVERT_TO_BINARY". Default: "CONVERT_TO_TEXT"
#   authorizers:                       # (Optional) Authorizer catalogue; entries with authtype "lambda" are injected as securitySchemes. Default: []
#     - name: "Lambda-Auth"            # (Required) Security scheme name, referenced from the spec "security" blocks.
#       authtype: "lambda"             # (Required) Only "lambda" is processed.
#       type: "request"                # (Optional) Valid values: "request", "token". Default: "request"
#       identity_source: "$request.header.Authorization" # (Optional) HTTP: "$request.header.X"; REST: "method.request.header.X". Default: "$request.header.Authorization"
#       result_ttl_seconds: 0          # (Optional) Authorizer cache TTL, 0 to 3600. Default: 0
#       payload_format_version: "2.0"  # (Optional) HTTP only. Valid values: "1.0", "2.0". Default: "2.0"
#       enable_simple_responses: false # (Optional) HTTP only, payload 2.0. Default: false
#       scheme:                        # (Optional) OpenAPI security scheme fields.
#         name: "Authorization"        # (Optional) Header/parameter name. Default: "Authorization"
#         in: "header"                 # (Optional) Valid values: "header", "query". Default: "header"
#         type: "apiKey"               # (Optional) Default: "apiKey"
#         authtype: "custom"           # (Optional) x-amazon-apigateway-authtype. Default: "custom"
#       lambda:                        # (Required) Existing authorizer Lambda.
#         function: "auth-dev"         # (Required) Lambda function name.
#         exec_role: "auth-dev-exec-role" # (Required) IAM role API Gateway assumes to invoke the authorizer.
variable "aws_configuration" {
  description = "(Required) API Gateway deployment options: stage, API type, endpoint, VPC links, logging, CORS, WAF, stage settings, authorizers and template parameters. aws_configuration.stage is mandatory. See the inline YAML documentation for every key. Default: {}."
  type        = any
  default     = {}
}

# apigw_definition:                    # (Required) API identity and source file.
#   name: "orders"                     # (Required) API name. In stage_only mode, the existing API looked up by this name.
#   version: "v1"                      # (Required) API version; part of descriptions and the log group name.
#   file_name: "orders"                # (Required) Spec file name without extension; <file_name>.json is used if present, else <file_name>.yaml.
#   domain_name: "api.dev.example.com" # (Optional) Existing API Gateway custom domain to map the stage to. Default: "" (no mapping)
#   mapping: "orders"                  # (Required when domain_name is set) Base path (API mapping key) on the custom domain.
#   stage_variables:                   # (Optional) Stage variables for this API. Default: []
#     - name: "api_variable"           # (Required) Stage variable name.
#       value: "api_value"             # (Required) Stage variable value.
variable "apigw_definition" {
  description = "(Required) API Gateway definition: name, version, spec file name, optional custom domain mapping and stage variables. See the inline YAML documentation. Default: {}."
  type        = any
  default     = {}
}

# absolute_path: "." # (Optional) Base directory used to resolve api_files_dir. With Terragrunt use get_terragrunt_dir(). Default: "."
variable "absolute_path" {
  description = "(Optional) Base directory used to resolve api_files_dir. Set it to the deployment directory (get_terragrunt_dir() in Terragrunt). Default: \".\"."
  type        = string
  default     = "."
}

# release:                    # (Optional) Release information, usually sourced from release.yaml. Default: {}
#   name: "orders"            # (Required when cloud_type = "lambda") Release name; the Lambda is "<name>-<environment>" and its role "<name>-<environment>-exec-role". Default: "default"
#   source:                   # (Optional) Informational source metadata.
#     name: "orders"          # (Optional) Source artifact name.
#     version: "1.2.3"        # (Optional) Source artifact version.
variable "release" {
  description = "(Optional) Release information (name, source). release.name resolves the backend Lambda function and execution role when cloud_type is lambda. Default: {}."
  type        = any
  default     = {}
}

# cloud_type: "lambda" # (Required) Backend runtime. Valid values: "lambda", "beanstalk", "eks", "kubernetes", "ecs". "lambda" enables the backend Lambda lookup, permission and template variables.
variable "cloud_type" {
  description = "(Required) Backend runtime type. Valid values: lambda, beanstalk, eks, kubernetes, ecs. lambda enables the backend Lambda lookup, invoke permission and Lambda template variables."
  type        = string
  validation {
    condition     = length(regexall("lambda|beanstalk|eks|kubernetes|ecs", var.cloud_type)) > 0
    error_message = "Only AWS types (lambda, beanstalk, eks, kubernetes, ecs) are supported as cloud type"
  }
}

# debug: false # (Optional) Write the rendered spec to <api_files_dir>/<file_name>_final.json and _final.yaml. Default: false
variable "debug" {
  description = "(Optional) Write the final rendered spec to <api_files_dir>/<file_name>_final.json and _final.yaml for inspection. Default: false."
  type        = bool
  default     = false
}
