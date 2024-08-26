##
# (c) 2024 - Cloud Ops Works LLC - https://cloudops.works/
#            On GitHub: https://github.com/cloudopsworks
#            Distributed Under Apache v2.0 License
#

data "aws_s3_bucket" "publish_bucket" {
  count  = try(var.aws_configuration.publish_bucket.enabled, false) == true ? 1 : 0
  bucket = var.aws_configuration.publish_bucket.name
}

resource "aws_s3_object" "publish_bucket_api" {
  for_each = {
    for apiname, api in local.all_apis : apiname => api
    if try(var.aws_configuration.publish_bucket.enabled, false) == true
  }
  bucket  = data.aws_s3_bucket.publish_bucket[0].bucket
  key     = "${try(var.aws_configuration.publish_bucket.prefix_path, "")}/${each.value.name}.yaml"
  content = yamlencode(each.value.content)
  tags    = var.extra_tags
}