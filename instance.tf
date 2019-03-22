data "aws_ami" "amzn-linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-*-x86_64-gp2"]
  }
}
resource "aws_instance" "proxily" {
  ami           = "${data.aws_ami.amzn-linux.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.proxilyEC2SecurityGroup.id}"]
  key_name = "${aws_key_pair.deployment.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.main.name}"
  tags {
    Name = "Proxily"
  }

  provisioner "file" {
    source      = "./install_codedeploy_agent.sh"
    destination = "/tmp/install_codedeploy_agent.sh"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "file" {
    source      = "awslogs.conf"
    destination = "/tmp/awslogs.conf"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_codedeploy_agent.sh",
      "/tmp/install_codedeploy_agent.sh ${var.aws_region}",
      "sudo yum install -y java-1.8.0",
      "sudo yum remove -y java-1.7.0-openjdk",
      "sudo yum install -y awslogs",
      "sudo mv /tmp/awslogs.conf /etc/awslogs/awslogs.conf",
      "sudo service awslogs start"
    ]
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "instance-profile"
  role = "${aws_iam_role.instance_profile.name}"
}

# create a service role for ec2 
resource "aws_iam_role" "instance_profile" {
  name = "instance-profile"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_key_pair" "deployment" {
  key_name   = "code-deploy-proxily"
  public_key = "${file(var.public_key_path)}"
}
resource "aws_security_group" "proxilyEC2SecurityGroup" {
  name = "proxilyEC2SecurityGroup"

  description = "Proxily EC2 Security group"
  vpc_id = "${module.vpc.default_vpc_id}"

  # All ports within
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}