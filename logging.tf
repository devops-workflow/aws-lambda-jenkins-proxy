//
// Cloudwatch logging setup
//

// API Gateway - Global settings
resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = "${aws_iam_role.cloudwatch.arn}"
}

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = "${aws_iam_role.cloudwatch.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

//
// Cloudwatch settings
//
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 14

  tags {
    "Description" = "Jenkins Trigger lambda logs"
    "Environment" = "${var.env}"
    "terraform"   = "true"
  }
}

resource "aws_cloudwatch_log_group" "prod-api-gateway" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.jenkins-trigger.id}/${aws_api_gateway_deployment.prod.stage_name}"
  retention_in_days = 14

  tags {
    "Description" = "Jenkins Trigger API Gateway logs"
    "Environment" = "${var.env}"
    "terraform"   = "true"
  }
}
