resource "aws_cloudwatch_log_group" "application_logs" {
  name = "ApplicationLog"
  retention_in_days = 30
}

resource "aws_iam_role_policy_attachment" "instance_profile_logs" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}