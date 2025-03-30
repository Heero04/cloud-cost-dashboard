/* 

This file defines EventBridge rules and associated resources for both scheduled and manual 
striggering of the Cost Explorer Lambda function. It includes:
  
  - Scheduled rule that runs every Friday at 12:00 UTC
  - Manual trigger rule for on-demand execution
  - Required EventBridge targets and Lambda permissions

*/

# -------------------------- Scheduled EventBridge Rule --------------------------

# EventBridge Rule for scheduled Lambda invocation
resource "aws_cloudwatch_event_rule" "cost_explorer_schedule" {
  name                = "cost-explorer-schedule"
  description         = "Triggers Lambda to fetch cost data every Friday at 12:00 UTC"
  schedule_expression = "cron(0 12 ? * FRI *)" # Every Friday at 12:00 UTC 
   #"rate(30 minutes)" # Testing
}

# EventBridge Target to trigger Lambda for scheduled execution
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.cost_explorer_schedule.name
  target_id = "cost-explorer-lambda"
  arn       = aws_lambda_function.cost_lambda.arn
}

# Lambda Permissions for EventBridge to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_explorer_schedule.arn
}

# -------------------------- Manual EventBridge Rule --------------------------

# Manual EventBridge Rule to manually trigger Lambda
resource "aws_cloudwatch_event_rule" "manual_cost_explorer_trigger" {
  name        = "manual-cost-explorer-trigger"
  description = "Manually triggers Lambda to fetch cost data"
  event_pattern = jsonencode({
    "source": ["custom.manual.trigger"],
    "detail-type": ["TestEvent"]
  })
}

# EventBridge Target for Manual Lambda Trigger
resource "aws_cloudwatch_event_target" "manual_lambda_target" {
  rule      = aws_cloudwatch_event_rule.manual_cost_explorer_trigger.name
  target_id = "manual-cost-explorer-lambda"
  arn       = aws_lambda_function.cost_lambda.arn
}

# Lambda Permissions for EventBridge to manually invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_manual" {
  statement_id  = "AllowManualExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.manual_cost_explorer_trigger.arn
}
