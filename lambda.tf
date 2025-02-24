resource "aws_lambda_function" "cost_lambda" {
  filename      = "lambda_function.zip"
  function_name = "CostExplorerLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  tags = {
    Name        = "CostExplorerLambda"
    Environment = "Production"
    Project     = "CloudCostDashboard"
  }
}
