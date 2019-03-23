resource "aws_cloudwatch_log_group" "application_logs" {
  name = "ApplicationLog"
  retention_in_days = 30
}

resource "aws_iam_role_policy_attachment" "instance_profile_logs" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_cloudwatch_log_group" "file_upload_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.file_upload_lambda.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = "${aws_iam_role.file_upload_exec_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}