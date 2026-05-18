variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "devops-project"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet where Jenkins lives"
  type        = string
  default     = "10.0.1.0/24"
}

variable "my_ip" {
  description = "Your public IP in CIDR notation e.g. 1.2.3.4/32"
  type        = string
}

variable "public_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/devops-key.pub"
}
