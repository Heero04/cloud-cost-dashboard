/*
 
This file defines an Athena database and Glue catalog table:
 
  - Analyzing cost data stored in CSV format
  - The table schema includes columns for cost, date, and service information

*/

# Athena Database definition (No encryption)
resource "aws_athena_database" "cost_data_db" {
  name   = "cost_data_db"
  bucket = aws_s3_bucket.cost_data_bucket.bucket
}

# Glue Table for Athena Querying
resource "aws_glue_catalog_table" "cost_data_table" {
  name          = "cost_data"
  database_name = aws_athena_database.cost_data_db.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification = "csv"
    EXTERNAL       = "TRUE"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.cost_data_bucket.bucket}/processed-cost-reports/"
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


