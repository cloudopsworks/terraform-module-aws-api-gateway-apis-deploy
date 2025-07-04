##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "aws_cloudwatch_log_group" "logging" {
  name              = "${local.default_log_location}/${local.deploy_stage_name}/${var.apigw_definition.name}/${var.apigw_definition.version}"
  retention_in_days = local.default_log_retention_days
  tags              = local.all_tags
}