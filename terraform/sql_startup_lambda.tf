resource "aws_lambda_function" "sql_startup_lambda" {
  function_name = "SQLStartupLambda"
  handler = "org.proxily.lambdas.sqlstartuplambda.SQLStartupLambda"
  runtime = "java8"
  filename = "../lambdas/sqlStartupLambda/target/SQLStartupLambda-1.0.jar"
  memory_size = "1024"
  timeout = 50
  vpc_config {
    subnet_ids = ["${module.vpc.private_subnets}", "${module.vpc.public_subnets}"]
    security_group_ids = ["${aws_security_group.proxilyDBSecurityGroup.id}"]
  }
  source_code_hash = "${filebase64sha256("../lambdas/sqlStartupLambda/target/SQLStartupLambda-1.0.jar")}"
  role = "${aws_iam_role.sql_startup_exec_role.arn}"

  environment {
    variables = {
      RDS_ENDPOINT = "${aws_db_instance.proxilyDB.endpoint}"
    }
  }
}

resource "aws_iam_role" "sql_startup_exec_role" {
  name = "SQLStartupLambdaExecRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sql_startup_exec_role_vpc" {
  role       = "${aws_iam_role.sql_startup_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "sql_startup_exec_role_rds" {
  role       = "${aws_iam_role.sql_startup_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}

## SNS subscriptions
resource "aws_sns_topic" "rds_startup" {
  name = "RDSStartup"
}
resource "aws_db_event_subscription" "creation" {
  name             = "rds-creation"
  sns_topic        = "${aws_sns_topic.rds_startup.arn}"
  source_type      = "db-instance"
  event_categories = ["creation"]
  source_ids       = ["${aws_db_instance.proxilyDB.id}"]
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = "${aws_sns_topic.rds_startup.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.sql_startup_lambda.arn}"
}

resource "aws_lambda_permission" "sql_startup_lambda_sns" {
  statement_id  = "AllowExecutionFromSNSSQLStartup"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sql_startup_lambda.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.rds_startup.arn}"
}