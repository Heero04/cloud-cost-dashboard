/* 

This file defines IAM roles and policies for multiple AWS services:

  Lambda Function:
  - IAM role with permissions for Cost Explorer, S3, SNS, CloudWatch Logs, and KMS
  - Policies for accessing cost data, storing in S3, sending alerts, logging, and encryption
 
  EventBridge:
  - IAM role for triggering Lambda functions on schedule
  - Policy to invoke Lambda functions
 
  Athena:
  - IAM role for querying data in S3
  - Policies for S3 access and KMS encryption
 
  AWS Glue:
  - IAM role for ETL jobs
  - Policies for S3 access (data and scripts), KMS encryption
  - Additional policies for listing buckets and accessing specific scripts

*/

# IAM role for Lambda function execution with necessary permissions
resource "aws_iam_role" "lambda_role" {
  name = "cost-dashboard-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "LambdaIAMRole"
    Environment = "Production"
    Project     = "CloudCostDashboard"
  }
}

# Policy allowing Lambda to access AWS Cost Explorer API
resource "aws_iam_policy" "cost_explorer_policy" {
  name        = "CostExplorerAccess"
  description = "Allows Lambda to fetch cost data from Cost Explorer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ce:GetCostAndUsage"]
      Resource = "*"
    }]
  })
}

# Attaches Cost Explorer policy to Lambda role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  policy_arn = aws_iam_policy.cost_explorer_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Policy allowing Lambda to read/write to S3 bucket
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Allows Lambda to store cost data in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "arn:aws:s3:::your-cost-data-bucket/*"
      }
    ]
  })
}

# Attaches S3 access policy to Lambda role
resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Policy allowing Lambda to publish to SNS topics
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "SNSPublishPolicy"
  description = "Allows Lambda to send cost alerts via SNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.cost_alerts.arn
      }
    ]
  })
}

# Attaches SNS publish policy to Lambda role
resource "aws_iam_role_policy_attachment" "sns_publish_attachment" {
  policy_arn = aws_iam_policy.sns_publish_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Policy allowing Lambda to write logs to CloudWatch
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "LambdaLoggingPolicy"
  description = "Allows Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# Attaches CloudWatch logging policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logging_attachment" {
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Grants KMS permissions to Lambda for encryption operations
resource "aws_kms_grant" "lambda_kms_access" {
  key_id            = aws_kms_key.s3_encryption_key.key_id
  grantee_principal = aws_iam_role.lambda_role.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

# IAM role for EventBridge to execute Lambda functions
resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "EventBridgeIAMRole"
    Environment = "Production"
    Project     = "CloudCostDashboard"
  }
}

# Policy allowing EventBridge to invoke Lambda functions
resource "aws_iam_policy" "eventbridge_lambda_policy" {
  name        = "EventBridgeInvokeLambdaPolicy"
  description = "Allows EventBridge to invoke Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.cost_lambda.arn
      }
    ]
  })
}

# Attaches Lambda invocation policy to EventBridge role
resource "aws_iam_role_policy_attachment" "eventbridge_lambda_attach" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_lambda_policy.arn
}

# Policy document defining Athena's S3 and KMS access permissions
data "aws_iam_policy_document" "athena_s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.cost_data_bucket.arn,
      "${aws_s3_bucket.cost_data_bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      aws_kms_key.s3_encryption_key.arn
    ]
  }
}

# Policy allowing Athena to access S3 and use KMS
resource "aws_iam_policy" "athena_s3_policy" {
  name   = "athena-s3-access-policy"
  policy = data.aws_iam_policy_document.athena_s3_access.json
}

# IAM role for Athena service
resource "aws_iam_role" "athena_role" {
  name = "athena_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "athena.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attaches S3 and KMS access policy to Athena role
resource "aws_iam_role_policy_attachment" "athena_s3_attachment" {
  role       = aws_iam_role.athena_role.name
  policy_arn = aws_iam_policy.athena_s3_policy.arn
}

# IAM role for AWS Glue service
resource "aws_iam_role" "glue_role" {
  name = "AWSGlueServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Combined policy for Glue's S3 and KMS access
resource "aws_iam_policy" "glue_s3_kms_access" {
  name = "AWSGlueS3KMSAccess"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow Glue to Access Cost Data Bucket
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::your-cost-data-bucket/cost-reports/*",
          "arn:aws:s3:::your-cost-data-bucket/processed-cost-reports/*"
        ]
      },

      # Allow Glue to Access the Script Bucket
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::your-script-bucket",
          "arn:aws:s3:::your-script-bucket/glue-scripts/*"
        ]
      },

      # Allow Glue to Use KMS for Decryption
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = aws_kms_key.s3_encryption_key.arn
      }
    ]
  })
}

# Attaches combined S3 and KMS access policy to Glue role
resource "aws_iam_role_policy_attachment" "glue_kms_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_kms_access.arn
}

# Policy allowing Glue to access scripts in S3
resource "aws_iam_policy" "glue_s3_script_access" {
  name        = "AWSGlueS3ScriptAccess"
  description = "Allows AWS Glue to get the script from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::your-cost-dashboard-scripts/glue-scripts/json_to_csv.py"
      }
    ]
  })
}

# Attaches script access policy to Glue role
resource "aws_iam_role_policy_attachment" "glue_s3_script_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_script_access.arn
}

# Policy allowing Glue to list S3 bucket contents
resource "aws_iam_policy" "glue_s3_list_access" {
  name        = "AWSGlueS3ListBucketAccess"
  description = "Allows AWS Glue to list the cost data bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::your-cost-data-bucket"
      }
    ]
  })
}

# Attaches bucket listing policy to Glue role
resource "aws_iam_role_policy_attachment" "glue_s3_list_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_list_access.arn
}
