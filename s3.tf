/* 

This file creates and configures S3 buckets for a cost dashboard solution:
- Creates a bucket for storing cost data with server-side encryption
- Sets up folders within the cost data bucket for raw JSON and processed CSV files
- Creates a separate bucket for storing Glue ETL scripts with proper access controls
- Uses Terraform Workspaces to differentiate between Dev and Prod environments

*/

# Creates the main S3 bucket to store cost data
resource "aws_s3_bucket" "cost_data_bucket" {
  bucket = "cost-data-${terraform.workspace}" # Creates 'cost-data-dev' or 'cost-data-prod'
}

# Configures server-side encryption using KMS for the cost data bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "cost_data_encryption" {
  bucket = aws_s3_bucket.cost_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_encryption_key.arn
    }
  }
}

# Creates a folder for storing raw JSON cost reports
resource "aws_s3_object" "json_folder" {
  bucket = aws_s3_bucket.cost_data_bucket.bucket
  key    = "cost-reports/"
  content = ""  # Creates an empty folder-like object
}

# Creates a folder for storing processed CSV cost reports
resource "aws_s3_object" "csv_folder" {
  bucket = aws_s3_bucket.cost_data_bucket.bucket
  key    = "processed-cost-reports/"
  content = ""  # Creates an empty folder-like object
}

# Creates an S3 bucket for storing Glue ETL scripts
resource "aws_s3_bucket" "script_bucket" {
  bucket = "script-bucket-${terraform.workspace}" # Creates 'script-bucket-dev' or 'script-bucket-prod'
}

# Blocks all public access to the scripts bucket
resource "aws_s3_bucket_public_access_block" "script_bucket" {
  bucket                  = aws_s3_bucket.script_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Attaches a policy allowing Glue service to access the scripts bucket
resource "aws_s3_bucket_policy" "script_bucket_policy" {
  bucket = aws_s3_bucket.script_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { Service = "glue.amazonaws.com" },
        Action = ["s3:GetObject", "s3:PutObject"],
        Resource = "${aws_s3_bucket.script_bucket.arn}/*"
      }
    ]
  })
}



