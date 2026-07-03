terraform {
  backend "s3" {
    bucket         = "triton-enterprise-tfstate" 
    key            = "bootstrap/terraform.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "triton-enterprise-tflocks"
    encrypt        = true
  }
}
