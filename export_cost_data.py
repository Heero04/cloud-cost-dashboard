import boto3
import pandas as pd
import json
from datetime import datetime, timedelta

# Initialize AWS Cost Explorer client
client = boto3.client('ce')

# Define time range (last 7 days)
start_date = (datetime.utcnow() - timedelta(days=7)).strftime('%Y-%m-%d')
end_date = datetime.utcnow().strftime('%Y-%m-%d')

# Fetch cost data
response = client.get_cost_and_usage(
    TimePeriod={'Start': start_date, 'End': end_date},
    Granularity='DAILY',
    Metrics=['UnblendedCost']
)

# Process results into a DataFrame
cost_data = []
for result in response["ResultsByTime"]:
    date = result["TimePeriod"]["Start"]
    amount = result["Total"]["UnblendedCost"]["Amount"]
    cost_data.append({"Date": date, "Cost (USD)": float(amount)})

df = pd.DataFrame(cost_data)

# Save to CSV and Excel
df.to_csv("aws_cost_data.csv", index=False)
df.to_excel("aws_cost_data.xlsx", index=False)

print("✅ AWS cost data exported to 'aws_cost_data.csv' and 'aws_cost_data.xlsx'")
