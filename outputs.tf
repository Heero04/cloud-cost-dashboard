/*

This Terraform code defines two output variables:
  - lambda_arn - Outputs the ARN (Amazon Resource Name) of the cost_lambda Lambda function
  - cost_alerts_topic_arn - Outputs the ARN of the cost_alerts SNS topic
  - These outputs allow other Terraform configurations to reference these ARN values
 
 */
 
output "lambda_arn" {
  value = aws_lambda_function.cost_lambda.arn
}

output "cost_alerts_topic_arn" {
  value = aws_sns_topic.cost_alerts.arn
}
