/* 

This file defines EventBridge rules and associated resources for both scheduled and manual 
triggering of the Cost Explorer Lambda function. It includes:
  
  - Scheduled rule that runs every Friday at 12:00 UTC
  - Manual trigger rule for on-demand execution
  - Required EventBridge targets and Lambda permissions
  - Uses Terraform Workspaces to separate Dev and Prod environments

*/

# -------------------------- Scheduled EventBridge Rule --------------------------

# EventBridge Rule for scheduled Lambda invocation
resource "aws_cloudwatch_event_rule" "cost_explorer_schedule" {
  name                = "cost-explorer-schedule-${terraform.workspace}" # Creates 'cost-explorer-schedule-dev' or 'cost-explorer-schedule-prod'
  description         = "Triggers Lambda to fetch cost data every Friday at 12:00 UTC for ${terraform.workspace}"
  schedule_expression = "cron(0 13 1 * ? *)"  # Runs at 13:00 UTC on the 1st day of every month
  #schedule_expression = "cron(0 12 ? * FRI *)" # Every Friday at 12:00 UTC
}

# EventBridge Target to trigger Lambda for scheduled execution
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.cost_explorer_schedule.name
  target_id = "cost-explorer-lambda-${terraform.workspace}" # Unique per environment
  arn       = aws_lambda_function.cost_lambda.arn
}

# Lambda Permissions for EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge-${terraform.workspace}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_explorer_schedule.arn
}

# -------------------------- Manual EventBridge Rule --------------------------

# Manual EventBridge Rule to manually trigger Lambda
resource "aws_cloudwatch_event_rule" "manual_cost_explorer_trigger" {
  name        = "manual-cost-explorer-trigger-${terraform.workspace}" # Creates 'manual-cost-explorer-trigger-dev' or 'manual-cost-explorer-trigger-prod'
  description = "Manually triggers Lambda to fetch cost data in ${terraform.workspace}"
  event_pattern = jsonencode({
    "source": ["custom.manual.trigger.${terraform.workspace}"],
    "detail-type": ["TestEvent"]
  })
}

# EventBridge Target for Manual Lambda Trigger
resource "aws_cloudwatch_event_target" "manual_lambda_target" {
  rule      = aws_cloudwatch_event_rule.manual_cost_explorer_trigger.name
  target_id = "manual-cost-explorer-lambda-${terraform.workspace}" # Unique per environment
  arn       = aws_lambda_function.cost_lambda.arn
}

# Lambda Permissions for EventBridge to manually invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_manual" {
  statement_id  = "AllowManualExecutionFromEventBridge-${terraform.workspace}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.manual_cost_explorer_trigger.arn
}
