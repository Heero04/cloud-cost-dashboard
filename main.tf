/* 

This code block configures the AWS provider for Terraform:
  - It specifies which AWS region to use for deploying resources
  - The region is set via a variable called aws_region

 */

provider "aws" {
  region = var.aws_region
}