provider "aws" {
  region = "${var.aws_region}"
}

provider "tls" {}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "video_bucket" {
  bucket = "proxily-post-video-${var.aws_region}"
  acl    = "private"
}
resource "aws_s3_bucket" "image_bucket" {
  bucket = "proxily-post-image-${var.aws_region}"
  acl    = "private"
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "proxily-vpc"
  cidr = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}