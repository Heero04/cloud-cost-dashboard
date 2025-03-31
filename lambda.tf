/* 

This Terraform code creates an AWS Lambda function for cost exploration and monitoring.
 - The function processes cost data, stores it in S3, and can send alerts via SNS.
 - It uses Python 3.9 runtime and includes environment variables for S3 bucket and SNS configuration.
 - Uses Terraform Workspaces to differentiate between Dev and Prod.

*/

# AWS Lambda function resource for cost exploration
resource "aws_lambda_function" "cost_lambda" {
  filename      = "lambda_function_v2.zip"
  function_name = "CostExplorerLambda-${terraform.workspace}" # Creates CostExplorerLambda-dev or CostExplorerLambda-prod
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  environment {
    variables = {
      S3_BUCKET     = "cost-data-${terraform.workspace}" # Creates cost-data-dev or cost-data-prod
      SNS_TOPIC_ARN = aws_sns_topic.cost_alerts.arn
    }
  }

  tags = {
    Name        = "CostExplorerLambda-${terraform.workspace}" # Tags it properly for Dev and Prod
    Environment = terraform.workspace
    Project     = "CloudCostDashboard"
  }
}
