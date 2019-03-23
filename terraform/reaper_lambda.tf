resource "aws_lambda_function" "reaper_lambda" {
  function_name = "ReaperLambda"
  handler = "org.proxily.lambdas.fileuploadlambda.ReaperLambda"
  runtime = "java8"
  filename = "../lambdas/reaperLambda/target/ReaperLambda-1.0.jar"
  memory_size = "1024"
  timeout = 50
  vpc_config {
    subnet_ids = ["${module.vpc.private_subnets}", "${module.vpc.public_subnets}"]
    security_group_ids = ["${aws_security_group.proxilyDBSecurityGroup.id}"]
  }
  source_code_hash = "${filebase64sha256("../lambdas/reaperLambda/target/ReaperLambda-1.0.jar")}"
  role = "${aws_iam_role.reaper_exec_role.arn}"

  environment {
    variables = {
      RDS_ENDPOINT = "${aws_db_instance.proxilyDB.endpoint}"
    }
  }
}

resource "aws_iam_role" "reaper_exec_role" {
  name = "ReaperLambdaExecRole"

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

resource "aws_cloudwatch_event_rule" "every_hour" {
    name = "every-hour"
    description = "Fires every hour"
    schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "reaper_every_hour" {
    rule = "${aws_cloudwatch_event_rule.every_hour.name}"
    target_id = "reaper"
    arn = "${aws_lambda_function.reaper_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_reaper" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.reaper_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_hour.arn}"
}
resource "aws_iam_role_policy_attachment" "reaper_exec_role_vpc" {
  role       = "${aws_iam_role.reaper_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "reaper_exec_role_rds" {
  role       = "${aws_iam_role.reaper_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}