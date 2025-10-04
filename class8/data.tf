data "aws_eip" "by_allocation_id" {
  id = "eipalloc-0e0fac707feec10ea"
}

# data.aws_eip.by_allocation_id.id
# use this if already existed or create a new one with reosurce block
data "aws_kms_key" "rds_kms" {
    key_id = "alias/dev-august-batch-rds"
}

# data.aws_kms_key.rds_kms.arn

data "aws_region" "current" {}

# data.aws_region.current.name

data "aws_caller_identity" "current" {}