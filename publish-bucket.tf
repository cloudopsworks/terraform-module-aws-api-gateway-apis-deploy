##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "aws_s3_bucket" "publish_bucket" {
  count  = try(var.aws_configuration.publish_bucket.enabled, false) == true ? 1 : 0
  bucket = var.aws_configuration.publish_bucket.name
}

resource "aws_s3_object" "publish_bucket_api" {
  count   = try(var.aws_configuration.publish_bucket.enabled, false) == true ? 1 : 0
  bucket  = data.aws_s3_bucket.publish_bucket[0].bucket
  key     = "${try(var.aws_configuration.publish_bucket.prefix_path, "")}/${var.apigw_definition.name}.yaml"
  content = yamlencode(local.content)
  tags    = var.extra_tags
}