/*
 
This file defines an Athena database and Glue catalog table:
 
  - Analyzing cost data stored in CSV format
  - The table schema includes columns for cost, date, and service information
  - Uses Terraform Workspaces to differentiate between Dev and Prod

*/

# Athena Database definition (No encryption)
resource "aws_athena_database" "cost_data_db" {
  name   = "cost_data_db_${terraform.workspace}" # Creates 'cost_data_db_dev' or 'cost_data_db_prod'
  bucket = aws_s3_bucket.cost_data_bucket.bucket
}

# Glue Table for Athena Querying
resource "aws_glue_catalog_table" "cost_data_table" {
  name          = "cost_data-${terraform.workspace}" # Creates 'cost_data-dev' or 'cost_data-prod'
  database_name = aws_athena_database.cost_data_db.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification = "csv"
    EXTERNAL       = "TRUE"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://cost-data-${terraform.workspace}/processed-cost-reports/" # Uses correct workspace bucket
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    columns {
      name = "cost"
      type = "string"
    }

    columns {
      name = "date"
      type = "date"
    }
    
    columns {
      name = "service"
      type = "string"
    }
    

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim" = "," 
        "skip.header.line.count" = "1"  
      }
    }
  }
}