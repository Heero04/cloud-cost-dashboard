""" This AWS Glue job performs the following operations:
  1. Reads command line arguments for job name, input and output paths
  2. Sets up Spark and Glue contexts for data processing
  3. Reads JSON data from S3 input path with multiline support
  4. Converts Spark DataFrame to Pandas DataFrame (Note: Only suitable for small datasets)
  5. Converts JSON data to CSV format using Pandas
  6. Uploads resulting CSV file to S3 output location with timestamp in filename
  7. Includes logging for successful completion and error cases
"""
import sys
import json
import csv
import logging
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
import boto3
import io
from datetime import datetime

# Configure Logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    # Get Job Arguments
    args = getResolvedOptions(sys.argv, ["JOB_NAME", "raw_data_path", "output_path"])

    # Initialize Spark & Glue Context
    sc = SparkContext()
    glueContext = GlueContext(sc)
    spark = glueContext.spark_session

    # Read JSON from S3
    df = spark.read.option("multiline", "true").json(args["raw_data_path"])

    # Flatten JSON (If needed)
    if "cost_item" in df.columns:
        df = df.selectExpr("explode(cost_item) as item").select("item.*")

    # Convert to Pandas for CSV Writing (for small datasets)
    pandas_df = df.toPandas()

    if not pandas_df.empty:
        csv_buffer = io.StringIO()
        pandas_df.to_csv(csv_buffer, index=False)

        # Upload CSV to S3 with timestamp in filename
        s3_client = boto3.client("s3")
        bucket_name = args["output_path"].split("/")[2]  # Extract bucket name
        object_key_prefix = "/".join(args["output_path"].split("/")[3:]).rstrip("/")  # Ensure folder structure
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"data_{timestamp}.csv"
        csv_key = f"{object_key_prefix}/{filename}" if object_key_prefix else filename

        s3_client.put_object(
            Bucket=bucket_name,
            Key=csv_key,
            Body=csv_buffer.getvalue(),
            ContentType="text/csv" 
        )

        logger.info("CSV file successfully written to S3.")


    else:
        logger.warning("No data found in JSON file.")

except Exception as e:
    logger.error(f"Error occurred: {str(e)}")
    raise

finally:
    # Clean up Spark context
    if 'sc' in locals():
        sc.stop()

