variable "project_name" {
  type = string
  default = "jmw7115-dea-challenge"
}

variable "bucket_name" {
  type = string
  default = "jmw7115-dea-challenge-data-bucket"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}