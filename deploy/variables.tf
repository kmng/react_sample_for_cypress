variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}


variable "stack_name" {
  type = string
}


variable "admin_email_addresses" {
  type    = list(string)
  default = ["admin1@example.com", "admin2@example.com"]
}