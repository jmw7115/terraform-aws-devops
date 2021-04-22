terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" { # terraform aws provider
  profile = "default"
  region  = var.aws_region
}

######## S3 Bucket to store files
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object

resource "aws_s3_bucket" "data-bucket" {
  bucket = "${var.project_name}-bucket"
  acl    = "private"

  # jw: only include this if you do not want the data.
  force_destroy = true

  versioning {
    enabled = true
  }

  tags = {
    Name        = var.project_name
    Environment = "Dev"
  }

}

# Bucket resource for data uploads
# This folder will need a trigger to append the data
# to the active data file in Active-Data/data.csv.
resource "aws_s3_bucket_object" "data-input-folder" {
    bucket = aws_s3_bucket.data-bucket.id
    acl    = "private"
    key    = "Input-Data/"
    source = "/dev/null"
}

# Bucket resource where the lambda funciton will retrieve 
# data.
resource "aws_s3_bucket_object" "active-data-folder" {
    bucket = aws_s3_bucket.data-bucket.id
    acl    = "private"
    key    = "Active-Data/"
    source = "/dev/null"
}

# Bucket resource where the uploaded data will be 
# stored after processing.
resource "aws_s3_bucket_object" "archive-data-folder" {
    bucket = aws_s3_bucket.data-bucket.id
    acl    = "private"
    key    = "Archive-Data/"
    source = "/dev/null"
}

## Upload the initial file
resource "aws_s3_bucket_object" "rates-file-upload" {
  bucket = aws_s3_bucket.data-bucket.id
  key    = "data.csv"
  source = "data-files/data.csv"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  # etag = filemd5("path/to/file")
}

## Access to S3 Bucket Policy

# resource "aws_s3_bucket_policy" "data-bucket-policy" {
#   bucket = aws_s3_bucket.data-bucket.id

#   # This needs more work ... -jw
#   policy = <<POLICY
# {
#   "Id": "Policy1619122712422",
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "Stmt1619122700502",
#       "Action": "s3:*",
#       "Effect": "Allow",
#       "Resource": "arn:aws:s3:::${var.project_name}-bucket/*",
#       "Principal": "*"
#     }
#   ]
# }
# POLICY
# }

resource "aws_s3_bucket_policy" "data-bucket-policy" {
  bucket = aws_s3_bucket.data-bucket.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = "arn:aws:s3:::${var.project_name}-bucket/*"
      },
    ]
  })
}
