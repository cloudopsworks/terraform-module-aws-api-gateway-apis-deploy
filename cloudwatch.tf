##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

resource "aws_cloudwatch_log_group" "logging" {
  for_each          = local.all_apis
  name              = "${local.default_log_location}/${local.deploy_stage_name}/${each.value.name}"
  retention_in_days = local.default_log_retention_days
  tags              = local.all_tags
}