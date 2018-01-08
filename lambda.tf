
/*
# lambda resources: 4
https://www.terraform.io/docs/providers/aws/r/lambda_alias.html
https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html
https://www.terraform.io/docs/providers/aws/r/lambda_function.html
https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
*/


resource "aws_lambda_function" "test_lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "jenkins-trigger-proxy"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "exports.test"
  source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  runtime          = "nodejs6.10"
  environment {
    variables = {
      foo = "bar"
    }
  }
}
