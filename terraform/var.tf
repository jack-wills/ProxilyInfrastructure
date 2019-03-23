variable "aws_region" {
  default = "us-east-1"
}

variable "stage" {
  default = "beta"
}


variable "public_key_path" {
  description = "Path to a public ssh key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to a private ssh key"
  default     = "~/.ssh/id_rsa"
}