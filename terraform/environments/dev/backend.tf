# MVP/Dev Only: Using a local backend for rapid prototyping and local development.
# Production Direction: Migrate this to an S3/GCS/Azure Blob backend
# with state locking (e.g., DynamoDB) before deploying to EKS/GKE in production.
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
