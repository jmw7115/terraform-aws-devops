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

######## S3 Bucket Resources to store files
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
  key    = "Active-Data/data.csv"
  source = "data-files/data.csv"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  # etag = filemd5("path/to/file")
}

## Access to S3 Bucket Policy

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

######## Lambda Resources

# Not 100% sure about the roles and policies
# Need to review

resource "aws_iam_role" "lambda_execute_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}


# Took the easy way out and add all S3,
# Not the most secure, needs more work.
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-lambda-policy"
  description = "Policy for S3 Resource Access"

  policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.project_name}-bucket"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda-attach" {
  role       = aws_iam_role.lambda_execute_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
# https://github.com/hashicorp/terraform/issues/27774
# https://docs.aws.amazon.com/lambda/latest/dg/python-handler.html

# This works but need to git role into arn variable
# Not sure where I should place the local zip for the function function.
# More research needed.
resource "aws_lambda_function" "query-data-lambda" {
  function_name = "data-query-function"
  # role          = "arn:aws:iam::418788601002:role/jmw7115-devops-challenge-lambda-role"
  role          = "${aws_iam_role.lambda_execute_role.arn}"
  filename      = "lambda_function.py.zip"
  handler       = "lambda_function.lambda_handler"
  runtime = "python3.8"

}




# resource "aws_lambda_function" "lambda_2" {
#   filename      = "jmw7115-project-1-select-all-function-7c276612-6bd0-4944-8cb8-a08fc400e659.zip"
#   function_name = "lambda_2"
#   role          = aws_iam_role.lambda_role.arn
#   # handler       = "hello kitty"
#   # The filebase64sha256() function is available in Terraform 0.11.12 and later
#   # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
#   # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
#   # source_code_hash = filebase64sha256("jmw7115-project-1-select-all-function-7c276612-6bd0-4944-8cb8-a08fc400e659.zip")
#   source_code_hash = filebase64sha256("jmw7115-project-1-select-all-function-7c276612-6bd0-4944-8cb8-a08fc400e659.zip")

#   runtime = "python3.8"

# }

# resource "aws_lambda_function" "lambda_3" {
#   filename      = "jmw7115-project-1-select-all-function-7c276612-6bd0-4944-8cb8-a08fc400e659.zip"
#   function_name = "lambda_3"
#   role          = aws_iam_role.lambda_role.arn
#   # handler       = "hello kitty"
#   # The filebase64sha256() function is available in Terraform 0.11.12 and later
#   # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
#   # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
#   # source_code_hash = filebase64sha256("jmw7115-project-1-select-all-function-7c276612-6bd0-4944-8cb8-a08fc400e659.zip")
#   source_code_hash = filebase64sha256("jmw7115-project-1-select-all-function-7c276612-6bd0-4944-8cb8-a08fc400e659.zip")

#   runtime = "python3.8"

# }
