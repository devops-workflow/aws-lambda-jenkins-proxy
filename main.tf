
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
      HEADERS = "Content-Type"
      JENKINS_PSWD = ""
      JENKINS_USER = ""
      TARGET_HOSTNAME = ""
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
