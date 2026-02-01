terraform {
  backend "s3" {
    bucket         = "charlie-dev12212025"
    key            = "state/terraform.tfstate"
    dynamodb_table = "charlie-dev12212025"
  }
}
