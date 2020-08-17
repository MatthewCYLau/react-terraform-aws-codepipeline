provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "matlau-react-aws-codepipeline2" {
  bucket = "matlau-react-aws-codepipeline2"
  acl    = "public-read"
  policy = file("policy.json")

  website {
    index_document = "index.html"
  }
}