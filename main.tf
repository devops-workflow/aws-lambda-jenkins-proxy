
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
data "aws_caller_identity" "current" {}
data "aws_vpc" "vpc" {
  tags {
    Env = "${var.env}"
  }
}
data "aws_subnet_ids" "private_subnet_ids" {
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags {
    Network = "Private"
  }
}

//
// Lambda
//
module "lambda-sg" {
  #source       = "git@github.com:devops-workflow/terraform-aws-security-group.git"
  source        = "devops-workflow/security-group/aws"
  version       = "2.0.0"
  name          = "jenkins-trigger lambda access"
  description   = "jenkins-trigger lambda access"
  environment   = "${var.env}"
  vpc_id        = "${data.aws_vpc.vpc.id}"
  egress_rules  = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "52.27.240.72/32"
      description = "VPN One"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "34.211.24.239/32"
      description = "Jenkins Public IP"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "10.101.0.0/16"
      description = "VPC One"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "73.231.134.185/32"
      description = "San Mateo, VPN"
    }
  ]
  tags = {
    Description = "Jenkins trigger lambda access"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com",
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
    effect = "Allow"
  }
}
data "aws_iam_policy_document" "LambdaPerms" {
  statement {
    actions   = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}
resource "aws_iam_role_policy" "LambdaPerms" {
    name    = "LambdaVPCPermissions"
    role    = "${aws_iam_role.iam_for_lambda.id}"
    policy  = "${data.aws_iam_policy_document.LambdaPerms.json}"
}
resource "aws_iam_role" "iam_for_lambda" {
  name = "jenkins-trigger"
  #path               = "${var.aws_iam_role_path}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}
/*
resource "aws_iam_role_policy" "lambda" {
  count  = "${length(local.aws_iam_role_policy)}"
  name   = "${lookup(local.aws_iam_role_policy[count.index], "name", "${var.name}-policy-${count.index}")}"
  role   = "${aws_iam_role.lambda.name}"
  policy = "${lookup(local.aws_iam_role_policy[count.index], "policy")}"
}
resource "aws_iam_role_policy_attachment" "lambda" {
  count      = "${length(local.aws_iam_role_policy_attachment_policy_arn)}"
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "${element(local.aws_iam_role_policy_attachment_policy_arn, count.index)}"
}
*/
data "archive_file" "lambda" {
  type = "zip"
  source_file = "${path.module}/index.js"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "test_lambda" {
  description       = "Proxy for triggering Jenkins jobs"
  filename         = "${data.archive_file.lambda.output_path}"
  function_name    = "test-jenkins-trigger-proxy"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda.output_path}"))}"
  runtime          = "nodejs6.10"
  publish           = true
  environment {
    variables = {
      HEADERS = "${var.headers}"
      JENKINS_PSWD = "${var.jenkins_pswd}"
      JENKINS_USER = "${var.jenkins_user}"
      TARGET_HOSTNAME = "${var.jenkins_host}"
      TARGET_PATH = "/"
      TARGET_METHOD = "GET"
    }
  }
  vpc_config {
    security_group_ids  = ["${list(module.lambda-sg.id)}"]
    subnet_ids          = ["${data.aws_subnet_ids.private_subnet_ids.ids}"]
  }
  tags {
     "Description"  = "TEST Proxy for triggering Jenkins jobs"
     "terraform"    = "true"
  }
}

output "security_group_ids" {
  value = "${module.lambda-sg.id}"
}
output "subnet_ids" {
  value = "${data.aws_subnet_ids.private_subnet_ids.ids}"
}

//
// API Gateway
//
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
*/

# https://andydote.co.uk/2017/03/17/terraform-aws-lambda-api-gateway/
# https://digitalronin.github.io/2017/06/12/terraform-aws-lambda.html
#   https://github.com/digitalronin/terraform-lambda-helloworld

resource "aws_api_gateway_rest_api" "jenkins-trigger" {
  name        = "test-jenkins-trigger"
  description = "Trigger for Jenkins jobs"
}
/*
resource "aws_api_gateway_stage" "ci" {
  stage_name    = "ci2"
  description   = "Continueos Integration"
  rest_api_id   = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  deployment_id = "${aws_api_gateway_deployment.prod.id}"
}
*/

resource "aws_api_gateway_api_key" "CircleCI" {
  name        = "CircleCI2"
  description = "Access for CircleCI"
}

resource "aws_api_gateway_usage_plan" "CircleCI" {
  name         = "CircleCI2"
  description  = "CircleCI usage"
  api_stages {  # jenkins-builder
    api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
    stage  = "${aws_api_gateway_deployment.prod.stage_name}"
  }
  throttle_settings {
    burst_limit = 100
    rate_limit  = 10
  }
}
resource "aws_api_gateway_usage_plan_key" "CircleCI" {
  key_id        = "${aws_api_gateway_api_key.CircleCI.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.CircleCI.id}"
}
# Attach resources to other resources to create path
# /{JobName}/{JobToken}/{BuildCause}
resource "aws_api_gateway_resource" "job_name" {
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  parent_id   = "${aws_api_gateway_rest_api.jenkins-trigger.root_resource_id}"
  path_part   = "{JobName}"
}
resource "aws_api_gateway_resource" "job_token" {
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  parent_id   = "${aws_api_gateway_resource.job_name.id}"
  path_part   = "{JobToken}"
}
resource "aws_api_gateway_resource" "build_cause" {
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  parent_id   = "${aws_api_gateway_resource.job_token.id}"
  path_part   = "{BuildCause}"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id       = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  resource_id       = "${aws_api_gateway_resource.build_cause.id}"
  http_method       = "GET"
  authorization     = "NONE"
  api_key_required  = true
  request_parameters = {
    "method.request.querystring.BUILD_NUMS" = true,
    "method.request.querystring.GIT_REF"    = true,
    "method.request.querystring.ORG"        = true,
    "method.request.querystring.PROJECT"    = true
  }
}
# method WORKs no error, but sure what the affect is:
#     "method.request.path.XXX" = true
# gtwy integ: "integration.request.path.id" = "method.request.path.accountId"

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  resource_id             = "${aws_api_gateway_resource.build_cause.id}"
  http_method             = "${aws_api_gateway_method.get.http_method}"
  type                    = "AWS"
  uri   = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${aws_lambda_function.test_lambda.function_name}/invocations"
  integration_http_method = "GET"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  #cache_key_parameters = ["method.request.path.param"]
  #cache_namespace      = "foobar"
  request_parameters = {
    "integration.request.querystring.BUILD_NUMS" = "method.request.querystring.BUILD_NUMS",
    "integration.request.querystring.GIT_REF"    = "method.request.querystring.GIT_REF",
    "integration.request.querystring.ORG"        = "method.request.querystring.ORG",
    "integration.request.querystring.PROJECT"    = "method.request.querystring.PROJECT"
  }
  /*request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }*/
  # Transforms the incoming XML request to JSON
  request_templates {
    "application/json" = <<REQUEST_TEMPLATE
{  "headers": {
    "Content-Type": "application/json"
  },
 "body":{
   "JobName": "$input.params('JobName')",
   "JobToken": "$input.params('JobToken')",
   "BuildCause": "$input.params('BuildCause')"
}}
REQUEST_TEMPLATE
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  resource_id = "${aws_api_gateway_resource.build_cause.id}"
  http_method = "${aws_api_gateway_method.get.http_method}"
  status_code = "200"
  response_models = {
    "application/json"  = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "GetIntegrationResponse" {
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  resource_id = "${aws_api_gateway_resource.build_cause.id}"
  http_method = "${aws_api_gateway_method.get.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  # Transforms the backend JSON response to XML
  /*response_templates {
    "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }*/
}

/*
resource "aws_api_gateway_deployment" "dev" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  stage_name = "dev"
}
*/
resource "aws_api_gateway_deployment" "prod" {
  depends_on = [
    "aws_api_gateway_method.get",
    "aws_api_gateway_integration.lambda"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
  stage_name  = "ci2"
}

// Document methods
resource "aws_api_gateway_documentation_part" "GetTrigger" {
  location {
    #name    = "BuildCause"
    type    = "METHOD"
    method  = "GET"
    path    = "/{JobName}/{JobToken}/{BuildCause}"
  }
  properties  = "{\"description\":\"What caused this request to be triggered?\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
// Document URL path
resource "aws_api_gateway_documentation_part" "PathBuildCause" {
  location {
    type    = "PATH_PARAMETER"
    name    = "BuildCause"
    method  = "GET"
    path    = "/{JobName}/{JobToken}/{BuildCause}"
  }
  properties  = "{\"description\":\"What caused this request to be triggered?\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
resource "aws_api_gateway_documentation_part" "PathJobName" {
  location {
    type    = "PATH_PARAMETER"
    name    = "JobName"
    method  = "GET"
    path    = "/{JobName}"
  }
  properties  = "{\"description\":\"Name of the Jenkins Job to trigger\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
resource "aws_api_gateway_documentation_part" "PathJobToken" {
  location {
    type    = "PATH_PARAMETER"
    name    = "JobToken"
    method  = "GET"
    path    = "/{JobName}/{JobToken}"
  }
  properties  = "{\"description\":\"Jenkins Job Token for triggering the specified job\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
// Document query parameters
resource "aws_api_gateway_documentation_part" "QueryGitRef" {
  location {
    type    = "QUERY_PARAMETER"
    name    = "GIT_REF"
    method  = "GET"
    path    = "/{JobName}/{JobToken}/{BuildCause}"
  }
  properties  = "{\"description\":\"Git reference of build\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
resource "aws_api_gateway_documentation_part" "QueryBuildNums" {
  location {
    type    = "QUERY_PARAMETER"
    name    = "BUILD_NUMS"
    method  = "GET"
    path    = "/{JobName}/{JobToken}/{BuildCause}"
  }
  properties  = "{\"description\":\"Comma separated list of CIrcleCI build numbers to get artifacts from\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
resource "aws_api_gateway_documentation_part" "QueryOrg" {
  location {
    type    = "QUERY_PARAMETER"
    name    = "ORG"
    method  = "GET"
    path    = "/{JobName}/{JobToken}/{BuildCause}"
  }
  properties  = "{\"description\":\"GitHub organization or user where project repo is\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
resource "aws_api_gateway_documentation_part" "QueryProject" {
  location {
    type    = "QUERY_PARAMETER"
    name    = "PROJECT"
    method  = "GET"
    path    = "/{JobName}/{JobToken}/{BuildCause}"
  }
  properties  = "{\"description\":\"GitHub project repo name\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

/*
output "dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}*/

output "prod_url" {
  value = "https://${aws_api_gateway_deployment.prod.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.prod.stage_name}"
}
