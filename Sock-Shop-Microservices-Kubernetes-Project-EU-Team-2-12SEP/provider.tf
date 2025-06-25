# Configure the AWS Provider
provider "aws" {
  region = var.region
profile = "K8S"
shared_credentials_files = ["~/.aws/credentials"]
}
