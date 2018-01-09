
/*
# lambda resources: 4
https://www.terraform.io/docs/providers/aws/r/lambda_alias.html
https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html
https://www.terraform.io/docs/providers/aws/r/lambda_function.html
https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
*/

# https://digitalronin.github.io/2017/06/12/terraform-aws-lambda.html
# https://digitalronin.github.io/2017/06/12/terraform-aws-lambda.html
#   https://github.com/digitalronin/terraform-lambda-helloworld
# https://medium.com/build-acl/aws-lambda-deployment-with-terraform-24d36cc86533

resource "aws_iam_role" "example_api_role" {
  name = "example_api_role"
  #assume_role_policy = "${file("policies/lambda-role.json")}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "apigateway.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "lambda" {
  type = "zip"
  source_file = "index.js"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "test_lambda" {
  description       = "Proxy for triggering Jenkins jobs"
  filename         = "${data.archive_file.lambda.output_path}"
  function_name    = "jenkins-trigger-proxy"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda.output_path}"))}"
  runtime          = "nodejs6.10"
  publish           = true
  environment {
    variables = {
      HEADERS = '["Content-Type"]'
      JENKINS_PSWD = "7c2c19113f3bc56df4be8ad624a97118dc01fbd6"
      JENKINS_USER = "wiser-ci"
      TARGET_HOSTNAME = "jenkins.one.wiser.com"
      TARGET_PATH = "/"
      TARGET_METHOD = "GET"
    }
  }
  #vpc_config
  tags {
     "Description" = "Proxy for triggering Jenkins jobs"
     "terraform" = "true"
  }
}
