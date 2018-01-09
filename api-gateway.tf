
/*
https://github.com/kurron/terraform-aws-api-key
https://github.com/kurron/terraform-aws-api-gateway-binding
https://github.com/kurron/terraform-aws-api-gateway
https://github.com/kurron/terraform-aws-api-gateway-deployment
*/
/*
# API Gateway resources:20
https://www.terraform.io/docs/providers/aws/r/api_gateway_account.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_api_key.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_authorizer.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_base_path_mapping.html

https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_integration_response.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_method.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_method_response.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_method_settings.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_model.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_rest_api.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_stage.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_usage_plan.html
https://www.terraform.io/docs/providers/aws/r/api_gateway_usage_plan_key.html

# lambda resources: 4
https://www.terraform.io/docs/providers/aws/r/lambda_alias.html
https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html
https://www.terraform.io/docs/providers/aws/r/lambda_function.html
https://www.terraform.io/docs/providers/aws/r/lambda_permission.html
*/

# https://andydote.co.uk/2017/03/17/terraform-aws-lambda-api-gateway/
# https://digitalronin.github.io/2017/06/12/terraform-aws-lambda.html
#   https://github.com/digitalronin/terraform-lambda-helloworld

resource "aws_api_gateway_rest_api" "MyDemoAPI" {
  name        = "MyDemoAPI"
  description = "This is my API for demonstration purposes"
}

resource "aws_api_gateway_stage" "ci" {
  stage_name    = "ci"
  description   = ""
  rest_api_id   = "${aws_api_gateway_rest_api.test.id}"
  deployment_id = "${aws_api_gateway_deployment.test.id}"
}

resource "aws_api_gateway_api_key" "CircleCI" {
  name        = "CircleCI"
  description = ""
  stage_key {
    rest_api_id = "${aws_api_gateway_rest_api.MyDemoAPI.id}"
    stage_name  = "${aws_api_gateway_deployment.MyDemoDeployment.stage_name}"
  }
}

resource "aws_api_gateway_usage_plan" "CircleCI" {
  name         = "CircleCI"
  description  = "my description"
  api_stages {  # jenkins-builder
    api_id = "${aws_api_gateway_rest_api.myapi.id}"
    stage  = "${aws_api_gateway_deployment.dev.stage_name}"
  }
  throttle_settings {
    burst_limit = 100
    rate_limit  = 10
  }
}

resource "aws_api_gateway_resource" "MyDemoResource" {
  rest_api_id = "${aws_api_gateway_rest_api.MyDemoAPI.id}"
  parent_id   = "${aws_api_gateway_rest_api.MyDemoAPI.root_resource_id}"
  path_part   = "mydemoresource"
}
# Attach resources to other resources to create path
# /{JobName}/{JobToken}/{BuildCause}

resource "aws_api_gateway_method" "MyDemoMethod" {
  rest_api_id   = "${aws_api_gateway_rest_api.MyDemoAPI.id}"
  resource_id   = "${aws_api_gateway_resource.MyDemoResource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "MyDemoIntegration" {
  rest_api_id          = "${aws_api_gateway_rest_api.MyDemoAPI.id}"
  resource_id          = "${aws_api_gateway_resource.MyDemoResource.id}"
  http_method          = "${aws_api_gateway_method.MyDemoMethod.http_method}"
  type                 = "AWS_PROXY"
  uri      = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.example_test_function.function_name}/invocations"
  integration_http_method = "GET"
  #cache_key_parameters = ["method.request.path.param"]
  #cache_namespace      = "foobar"
  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }
  # Transforms the incoming XML request to JSON
  request_templates {
    "application/xml" = <<REQUEST_TEMPLATE
{
   "body" : $input.json('$')
}
REQUEST_TEMPLATE
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.MyDemoAPI.id}"
  resource_id = "${aws_api_gateway_resource.MyDemoResource.id}"
  http_method = "${aws_api_gateway_method.MyDemoMethod.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = "${aws_api_gateway_rest_api.MyDemoAPI.id}"
  resource_id = "${aws_api_gateway_resource.MyDemoResource.id}"
  http_method = "${aws_api_gateway_method.MyDemoMethod.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  # Transforms the backend JSON response to XML
  response_templates {
    "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }
}

resource "aws_api_gateway_deployment" "example_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  stage_name = "dev"
}

resource "aws_api_gateway_deployment" "example_deployment_prod" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  stage_name = "api"
}

output "dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}

output "prod_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_prod.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_prod.stage_name}"
}
