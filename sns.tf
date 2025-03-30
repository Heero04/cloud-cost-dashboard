/*

 This Terraform code creates an SNS topic for cost alerts and sets up two subscriptions:
   - An email subscription to receive cost alerts via email

*/

# Creates the SNS topic that will be used to send cost alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "CostAlertsTopic"
}

# Creates an email subscription to the SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = "lawrencedavis1010@gmail.com"  # Change this to your real email
}

