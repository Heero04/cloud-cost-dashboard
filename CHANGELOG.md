# 📌 Changelog

## [v3.0]
### Added
- Terraform workspace support for dev/prod environments
- Added AWS security automation workflow (`aws-security.yml`):
  - OIDC authentication for AWS access
  - tfsec Terraform security scanning
  - AWS Well-Architected Tool integration
  - Trusted Advisor cost/security checks
  - CodeQL static analysis

- Added core CI workflow (`main.yml`):
  - Basic validation on push/PR
  - Foundation for future test expansion 

### Changed
- Workspace-scoped resource naming using ${terraform.workspace}
  - All AWS resources now include environment prefix/suffix
  - Ensures complete dev/prod separation
- Updated PowerBI dashboard data sources

## [v2.0] - 2025-03-30
### Major Project Upgrade: Cloud Cost Optimization Dashboard Overhaul
- **Fixed AWS Glue extraction** issues
- **Added Athena ODBC** to connecr to Power Bi
- **Included full dashboard file** with cost data for visualization
- **Uploaded screenshots** of overview & data soruce 
- **Enhanced security** with **IAM Least Privilege & KMS encryption**
- Set up **Lambda + EventBridge** for automated cost tracking
- Integrated **AWS Glue + S3** for JSON to CSV transformation
- Built **Power BI dashboard** to view cost analysis




