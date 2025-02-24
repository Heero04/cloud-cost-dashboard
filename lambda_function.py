import boto3
import json
import logging
import os
from datetime import datetime, timedelta
from decimal import Decimal

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'CostData')  # Use environment variable if possible
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        logger.info("Lambda function execution started.")
        logger.info(f"Received event: {json.dumps(event)}")
        
        client = boto3.client('ce')
        start_date = (datetime.utcnow() - timedelta(days=7)).strftime('%Y-%m-%d')
        end_date = datetime.utcnow().strftime('%Y-%m-%d')
        logger.info(f"Fetching cost data from {start_date} to {end_date}")

        response = client.get_cost_and_usage(
            TimePeriod={'Start': start_date, 'End': end_date},
            Granularity='DAILY',
            Metrics=['UnblendedCost']
        )
        logger.info(f"Raw cost data response: {json.dumps(response, indent=2)}")

        results = response.get("ResultsByTime", [])
        logger.info(f"Number of results to process: {len(results)}")

        if not results:
            logger.warning("No cost data returned from Cost Explorer.")
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({"message": "No cost data available"})
            }

        for result in results:
            date = result["TimePeriod"]["Start"]
            logger.info(f"Processing data for date: {date}")
            amount_str = result.get("Total", {}).get("UnblendedCost", {}).get("Amount", "0.00")

            if not amount_str or float(amount_str) == 0.00:
                logger.warning(f"No cost data available for {date}, skipping.")
                continue

            # Convert the cost to a Decimal
            amount = Decimal(amount_str)
            logger.info(f"✅ Processed Cost Data: {date} - ${amount}")
            logger.info(f"🔄 Writing to DynamoDB with item: {{'date': {date}, 'cost': {amount_str}}}")

            try:
                db_response = table.put_item(
                    Item={
                        "date": date,
                        "cost": amount
                    }
                )
                logger.info(f"✅ Successfully wrote {date} - ${amount} to DynamoDB. Response: {db_response}")
            except Exception as db_error:
                logger.error(f"❌ Failed to write to DynamoDB: {str(db_error)}", exc_info=True)

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({"message": "Processing complete"})
        }
    except Exception as e:
        logger.error("Error processing cost data", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }
