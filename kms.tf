/* 

This file creates:
  - An AWS KMS key for encrypting S3 bucket data with key rotation enabled and 30-day deletion window
  - An alias for the KMS key named "s3-cost-data-key" to make it easier to reference

*/


# KMS key used to encrypt data in S3 buckets with automatic key rotation enabled
resource "aws_kms_key" "s3_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# Create an alias for the KMS key that includes the workspace name for environment-specific identification
resource "aws_kms_alias" "s3_encryption_alias" {
  name          = "alias/s3-cost-data-key-${terraform.workspace}"
  target_key_id = aws_kms_key.s3_encryption_key.key_id
}
