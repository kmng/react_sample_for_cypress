variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "github_username" {
  default = "MatthewCYLau"
}

variable "github_project_name" {
  default = "react-terraform-aws-codepipeline"
}

variable "bucket_name" {
  default = "stefantopia-aws-react-codepipeline-bucket"
}