resource "aws_sns_topic" "cost_alerts" {
  name = "CostAlertsTopic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = "lawrencedavis1010@gmail.com"  # Change this to your real email
}
