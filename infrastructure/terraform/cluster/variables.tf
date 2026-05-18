variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "devops-project"
}

variable "cluster_name" {
  type    = string
  default = "devops-cluster"
}

variable "my_ip" {
  description = "Your public IP in CIDR notation e.g. 1.2.3.4/32"
  type        = string
}

variable "tf_state_bucket" {
  description = "S3 bucket holding Terraform state"
  type        = string
}
