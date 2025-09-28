data "aws_eip" "by_allocation_id" {
  id = "eipalloc-0073507ab19a71def"
}

# data.aws_eip.by_allocation_id.id

data "aws_kms_key" "rds_kms" {
    key_id = "alias/dev-rds-kms-key"
}

# data.aws_kms_key.rds_kms.arn