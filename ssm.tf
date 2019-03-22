
resource "aws_iam_role_policy_attachment" "instance_profile_ssm" {
  role       = "${aws_iam_role.instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}