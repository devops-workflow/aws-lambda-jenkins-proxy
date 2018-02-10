terraform {
  backend "s3" {
    dynamodb_table = "tf-state-lock"
    encrypt        = true
  }
}
