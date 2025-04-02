"""
AWS Cost Monitoring Lambda Function

This Lambda function performs the following steps:
1. Initializes AWS clients (Cost Explorer, S3, SNS) and sets up logging
2. Retrieves environment variables for S3 bucket and SNS topic
3. Defines a cost threshold for alerts
4. When triggered:
   - Sends initial SNS notification that Lambda was triggered
   - Calculates date range for previous month
   - Fetches cost data from AWS Cost Explorer for the previous month
   - Groups costs by AWS service
   - Processes cost data and generates alerts if costs exceed threshold
   - Stores cost report as JSON in S3 bucket
   - Sends notifications via SNS for any alerts/errors
5. Includes error handling and logging throughout execution
"""

import boto3
import json
import logging
import os
import calendar
from datetime import datetime, timedelta
from decimal import Decimal
import urllib3

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS Clients (Reused across invocations)
ce_client = boto3.client('ce')  # Cost Explorer client
s3_client = boto3.client('s3')  # S3 client
sns_client = boto3.client('sns')  # SNS client (for notifications)

# Environment Variables
s3_bucket = os.environ.get('S3_BUCKET')  # S3 bucket name
sns_topic_arn = os.environ.get('SNS_TOPIC_ARN', 'your-sns-topic-arn')  # SNS topic ARN


# Define cost threshold
COST_THRESHOLD = 10.00  # Modify as needed

# AWS Clients
glue_client = boto3.client("glue")  # Glue client


def lambda_handler(event, context):
    try:
        logger.info("🚀 Lambda function execution started.")
        
        # Send SNS Notification on Lambda Trigger
        send_sns_alert("✅ AWS Lambda Function Triggered", "AWS Lambda function executed successfully.")
        
        # Calculate the start of the year and end of the previous month
        today = datetime.today()

        # Calculate the first and last day of the previous month
        today = datetime.today()
        first_day_prev_month = today.replace(day=1) - timedelta(days=1)
        first_day_prev_month = first_day_prev_month.replace(day=1)
        last_day_prev_month = first_day_prev_month + timedelta(
            days=calendar.monthrange(first_day_prev_month.year, first_day_prev_month.month)[1] - 1
        )
        start_date = first_day_prev_month.strftime('%Y-%m-%d')
        end_date = last_day_prev_month.strftime('%Y-%m-%d')

        logger.info(f"Fetching cost data from {start_date} to {end_date}")
        
        # Fetch Cost Data from AWS Cost Explorer
        response = ce_client.get_cost_and_usage(
            TimePeriod={'Start': start_date, 'End': end_date},
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}]  # Breakdown by AWS Service
        )        
        
        results = response.get("ResultsByTime", [])
        
        if not results:
            logger.warning("⚠️ No cost data returned.")
            return {'statusCode': 200, 'body': json.dumps({"message": "No cost data available"})}
        
        # Process Cost Data: iterate over each service group
        cost_data = []
        for result in results:
            date = result["TimePeriod"]["Start"]
            groups = result.get("Groups", [])
            for group in groups:
                service = group.get("Keys", ["Unknown"])[0]
                amount = Decimal(group.get("Metrics", {}).get("UnblendedCost", {}).get("Amount", "0.00"))
                cost_data.append({"date": date, "service": service, "cost": f"${amount:.2f}"})
                
                if float(amount) > COST_THRESHOLD:
                    alert_msg = f"\U0001F6A8 Cost Alert: Your AWS cost for {service} on {date} is ${amount:.2f}, exceeding the threshold of ${COST_THRESHOLD}."
                    
        
        # Store cost data in S3
        file_name = f"cost_data_{start_date}.json"
        s3_path = f"cost-reports/{file_name}"
        
        s3_client.put_object(
            Bucket=s3_bucket,
            Key=s3_path,
            Body=json.dumps(cost_data, indent=2),
            ContentType="application/json"
        )
        logger.info(f"Cost data saved in S3")

        
        logger.info("Processing complete.")
        return {'statusCode': 200, 'body': json.dumps({"message": "Processing complete", "cost_data": cost_data})}
    
    except Exception as e:
        logger.error("Unexpected error processing cost data", exc_info=True)
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def send_sns_alert(subject, message):
    """
    Sends an SNS alert for cost thresholds or errors.
    """
    if not sns_topic_arn:
        logger.warning("SNS topic ARN not set. Skipping alert.")
        return
    
    try:
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=message,
            Subject=subject
        )
        logger.info(f"SNS Alert Sent: {subject}")
    except Exception as e:
        logger.error("Failed to send SNS alert. Check error details internally.")

