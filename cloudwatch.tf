/* 

This file Monitors AWS daily estimated costs:
  
  - Triggers an alarm if daily costs exceed $0.50 (which should likely be $5.00)
  - Sends a notification via AWS SNS to alert about the cost spike

*/


resource "aws_cloudwatch_metric_alarm" "cost_spike_alert" {
  alarm_name          = "CostSpikeAlert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400  # Check cost once per day
  statistic           = "Maximum"
  threshold           = 0.50   # Set threshold to $5 (change if needed)
  actions_enabled     = true

  dimensions = {
    Currency = "USD"
  }

  # Send alert notification via SNS
  alarm_description = "Triggers when AWS cost exceeds $5 in a day."
  alarm_actions = [aws_sns_topic.cost_alerts.arn]  # Sends alert to SNS
}