
# create bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  tags = {
    Name = var.bucket_name
  }
}
# block all public access
resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# enable versioning
resource "aws_s3_bucket_versioning" "versioning_example" {
  count  = var.if_versioning ? 1 : 0
  bucket = aws_s3_bucket.my_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# enable bucket logging
resource "aws_s3_bucket_logging" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  target_bucket = var.log_bucket
  target_prefix = "${aws_s3_bucket.my_bucket.id}log/"
}

#  enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket" {
  count  = var.if_encrypted ? 1 : 0
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}