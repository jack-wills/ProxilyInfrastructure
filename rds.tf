

resource "aws_db_instance" "proxilyDB" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.23"
  instance_class       = "db.t2.micro"
  name                 = "proxilyDB"
  username             = "admin"
  password             = "password"
  iam_database_authentication_enabled = true
  parameter_group_name = "default.mysql5.7"
  port                 = 3306
  vpc_security_group_ids = ["${aws_security_group.proxilyDBSecurityGroup.id}"]
}

resource "aws_security_group" "proxilyDBSecurityGroup" {
  name = "proxilyDBSecurityGroup"

  description = "RDS mysql server security group"
  vpc_id = "${module.vpc.default_vpc_id}"

  # Only mysql in
  ingress {
    from_port = 3306
    to_port = 3306
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
resource "aws_iam_policy" "rds_policy" {
  name        = "rds-policy"
  description = "RDS policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:DescribeDBInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "rds-db:connect"
        ],
        "Resource": [
            "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.proxilyDB.resource_id}/${aws_db_instance.proxilyDB.username}"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rds_attach" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "${aws_iam_policy.rds_policy.arn}"
}
