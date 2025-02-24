output "lambda_arn" {
  value = aws_lambda_function.cost_lambda.arn
}

output "dynamodb_table" {
  value = aws_dynamodb_table.cost_data.name
}
output "cost_alerts_topic_arn" {
  value = aws_sns_topic.cost_alerts.arn
}
