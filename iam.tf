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

resource "aws_iam_role_policy_attachment" "attach_policy" {
  policy_arn = aws_iam_policy.cost_explorer_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_policy" "dynamodb_write_policy" {
  name        = "DynamoDBWriteAccess"
  description = "Allows Lambda to write cost data to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:PutItem"]
      Resource = "arn:aws:dynamodb:*:*:table/CostData"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_write_attachment" {
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
  role       = aws_iam_role.lambda_role.name
}

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

resource "aws_iam_role_policy_attachment" "lambda_logging_attachment" {
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
  role       = aws_iam_role.lambda_role.name
}

