provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "react-aws-codepipeline-s3-bucket" {
  bucket        = var.bucket_name
  acl           = "public-read"
  policy        = file("bucket-policy.json")
  force_destroy = true

  website {
    index_document = "index.html"
  }
}

resource "aws_codepipeline" "react-aws-codepipeline" {
  name     = "react-aws-codepipeline2"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.react-aws-codepipeline-s3-bucket.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "MatthewCYLau"
        Repo       = "react-aws-codepipeline"
        Branch     = "master"
        OAuthToken = "${var.github_token}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "react-aws-codebuild"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.react-aws-codepipeline-s3-bucket.bucket
        Extract    = "true"
      }
    }
  }
}

resource "aws_codebuild_project" "react-aws-codebuild" {
  name          = "react-aws-codebuild"
  description   = "react-aws-codebuild"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
  }
}