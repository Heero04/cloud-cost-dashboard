/* 

This file sets up an AWS Glue data processing pipeline:
  - Creates a Glue Catalog database to store metadata about the cost data
  - Defines a Glue ETL job that converts JSON cost reports to CSV format
  - Creates a scheduled trigger to run the conversion job weekly on Fridays
  - Sets up a Glue crawler to automatically detect and catalog the schema of the processed CSV files
  - Uses Terraform Workspaces to separate Dev and Prod

*/

# Database to store the cost data schema and metadata
resource "aws_glue_catalog_database" "cost_data_db" { 
  name = "cost_data_db-${terraform.workspace}" # Creates 'cost_data_db-dev' or 'cost_data_db-prod'
}

# Glue ETL job that converts JSON cost reports to CSV format
resource "aws_glue_job" "json_to_csv" {
  name     = "convert-json-to-csv-${terraform.workspace}" # Creates 'convert-json-to-csv-dev' or 'convert-json-to-csv-prod'
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://glue-scripts-${terraform.workspace}-costdash/glue-scripts/json_to_csv.py"  
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"  = "python"
    "--TempDir"       = "s3://cost-data-${terraform.workspace}/glue-temp/"
    "--raw_data_path" = "s3://cost-data-${terraform.workspace}/cost-reports/"
    "--output_path"   = "s3://cost-data-${terraform.workspace}/processed-cost-reports/"
  }
}

# Scheduled trigger that runs the JSON to CSV conversion job weekly
resource "aws_glue_trigger" "json_to_csv_trigger" {
  name     = "convert-json-to-csv-trigger-${terraform.workspace}"
  type     = "SCHEDULED"
  schedule = "cron(0 13 1 * ? *)"  # Runs at 13:00 UTC on the 1st day of every month
  #schedule = "cron(0 13 ? * FRI *)"  # Runs every Friday at 13:00 UTC  

  actions {
    job_name = aws_glue_job.json_to_csv.name
  }
}

# Crawler that automatically detects and catalogs the schema of processed CSV files
resource "aws_glue_crawler" "csv_crawler" {
  name          = "csv_crawler-${terraform.workspace}" # Creates 'csv_crawler-dev' or 'csv_crawler-prod'
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.cost_data_db.name  # Reference updated for workspace support

  s3_target {
    path = "s3://cost-data-${terraform.workspace}/processed-cost-reports/"
  }

  schedule = "cron(10 4 * * ? *)"  # Runs at 4:10 AM UTC = 10:10 PM CST
}

