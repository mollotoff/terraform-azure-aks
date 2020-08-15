terraform {
  backend "s3" {
    bucket         = "{{CLUSTER_NAME}}"
    key            = "terraform.tfstate"
    region         = "{{REGION}}"
    # dynamodb_table = "test-eks-spot-locks"
    encrypt        = true
  }
}


