variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_repo" {
  description = "GitHub owner/repo allowed to assume the deploy role."
  type        = string
  default     = "shatchakra69/AWS-Student-Records"
}
