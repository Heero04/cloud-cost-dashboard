resource "aws_dynamodb_table" "cost_data" {
  name           = "CostData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "date"

  attribute {
    name = "date"
    type = "S"
  }

  tags = {
    Name        = "CostDataTable"
    Environment = "Production"
    Project     = "CloudCostDashboard"
  }
}
