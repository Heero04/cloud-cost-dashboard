/* 

This file sets up an AWS Glue data processing pipeline:
  - Creates a Glue Catalog database to store metadata about the cost data
  - Defines a Glue ETL job that converts JSON cost reports to CSV format
  - Creates a scheduled trigger to run the conversion job weekly on Fridays
  - Sets up a Glue crawler to automatically detect and catalog the schema of the processed CSV files

*/

# Database to store the cost data schema and metadata
resource "aws_glue_catalog_database" "cost_data_db" { 
  name = "cost_data_db"
}

# Glue ETL job that converts JSON cost reports to CSV format
resource "aws_glue_job" "json_to_csv" {
  name     = "convert-json-to-csv"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://your-cost-dashboard-scripts/glue-scripts/json_to_csv.py"  
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"  = "python"
    "--TempDir"       = "s3://your-cost-data-bucket/glue-temp/"
    "--raw_data_path" = "s3://your-cost-data-bucket/cost-reports/"
    "--output_path"   = "s3://your-cost-data-bucket/processed-cost-reports/"
  }
  
}

# Scheduled trigger that runs the JSON to CSV conversion job weekly
resource "aws_glue_trigger" "json_to_csv_trigger" {
  name     = "convert-json-to-csv-trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 13 ? * FRI *)"  # Runs every Friday at 13:00 UTC  # Runs every 5 minutes

  actions {
    job_name = aws_glue_job.json_to_csv.name
  }
}

# Crawler that automatically detects and catalogs the schema of processed CSV files
resource "aws_glue_crawler" "csv_crawler" {
  name          = "csv_crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.cost_data_db.name  # Fix reference

  s3_target {
    path = "s3://your-cost-data-bucket/processed-cost-reports/"
  }

  schedule = "cron(10 4 * * ? *)"  # Runs at 4:10 AM UTC = 10:10 PM CST

}
