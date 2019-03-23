resource "aws_lambda_function" "file_upload_lambda" {
  function_name = "FileUploadLambda"
  handler = "org.proxily.lambdas.fileuploadlambda.FileUploadLambda"
  runtime = "java8"
  filename = "../lambdas/fileUploadLambda/target/FileUploadLambda-1.0.jar"
  memory_size = "1028"
  timeout = 50
  vpc_config {
    subnet_ids = ["${module.vpc.private_subnets}", "${module.vpc.public_subnets}"]
    security_group_ids = ["${aws_security_group.proxilyDBSecurityGroup.id}"]
  }
  source_code_hash = "${filebase64sha256("../lambdas/fileUploadLambda/target/FileUploadLambda-1.0.jar")}"
  role = "${aws_iam_role.file_upload_exec_role.arn}"

  environment {
    variables = {
      RDS_ENDPOINT = "${aws_db_instance.proxilyDB.endpoint}"
    }
  }
}

resource "aws_iam_role" "file_upload_exec_role" {
  name = "FileUploadLambdaExecRole"

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

resource "aws_lambda_permission" "allow_bucket_video" {
  statement_id  = "AllowExecutionFromS3BucketVideo"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.file_upload_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.video_bucket.arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification_video" {
  bucket = "${aws_s3_bucket.video_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.file_upload_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_bucket_image" {
  statement_id  = "AllowExecutionFromS3BucketImage"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.file_upload_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.image_bucket.arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification_image" {
  bucket = "${aws_s3_bucket.image_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.file_upload_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
  }
}
resource "aws_iam_role_policy_attachment" "file_upload_exec_role_vpc" {
  role       = "${aws_iam_role.file_upload_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
resource "aws_iam_role_policy_attachment" "file_upload_exec_role_rds" {
  role       = "${aws_iam_role.file_upload_exec_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
}