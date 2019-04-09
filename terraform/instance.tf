data "aws_ami" "amzn-linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-*-x86_64-gp2"]
  }
}

data "template_file" "script" {

  vars {
    region = "${var.aws_region}"
    eip = "${aws_eip.instance_eip.id}"
  }
  template = <<EOF
#!/bin/bash
sudo yum -y update
sudo yum install -y ruby
cd /home/ec2-user
curl -O https://aws-codedeploy-$${region}.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo yum install -y java-1.8.0
sudo yum remove -y java-1.7.0-openjdk
sudo yum install -y awslogs
echo "${file("${path.module}/awslogs.conf")}" >> /tmp/awslogs.conf
sudo mv /tmp/awslogs.conf /etc/awslogs/awslogs.conf
sudo service awslogs start
sudo modprobe iptable_nat
iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 8443
aws configure set default.region $${region}
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id=$${eip}
  EOF

}

data "template_cloudinit_config" "config" {
  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.script.rendered}"
  }
}

resource "aws_launch_template" "proxily" {
  image_id = "${data.aws_ami.amzn-linux.id}"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.proxilyEC2SecurityGroup.id}"]
  key_name = "${aws_key_pair.deployment.key_name}"
  iam_instance_profile {
    name = "${aws_iam_instance_profile.main.name}"
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Proxily"
    }
  }

  user_data = "${base64encode(data.template_cloudinit_config.config.rendered)}"
}

resource "aws_autoscaling_group" "proxily" {
  availability_zones = ["us-east-1c"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1
  vpc_zone_identifier = ["${element(module.vpc.public_subnets,2)}"]

  launch_template {
    id      = "${aws_launch_template.proxily.id}"
    version = "$Latest"
  }
}

resource "aws_eip" "instance_eip" {
  vpc      = true
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

resource "aws_iam_policy" "instance_policy" {
  name = "instance_policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AssociateAddress"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_policy" {
  role = "${aws_iam_role.instance_profile.name}"
  policy_arn = "${aws_iam_policy.instance_policy.arn}"
}

resource "aws_key_pair" "deployment" {
  key_name   = "code-deploy-proxily"
  public_key = "${file(var.public_key_path)}"
}
resource "aws_security_group" "proxilyEC2SecurityGroup" {
  name = "proxilyEC2SecurityGroup"

  description = "Proxily EC2 Security group"
  vpc_id = "${module.vpc.vpc_id}"

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
    from_port = 443
    to_port = 443
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