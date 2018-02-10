output "api_id" {
  description = "API Gateway ID"
  value       = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

output "api_key_id" {
  description = "API Key ID"
  value       = "${aws_api_gateway_api_key.CircleCI.id}"
}

output "api_key_value" {
  description = "API Key value"
  value       = "${aws_api_gateway_api_key.CircleCI.value}"
}

/*output  "api_url" {
  description = "API Gateway URL"
  value       = ""
}*/

output "security_group_ids" {
  value = "${module.lambda-sg.id}"
}

output "subnet_ids" {
  value = "${data.aws_subnet_ids.private_subnet_ids.ids}"
}

/*
output "dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}*/

output "prod_url" {
  value = "https://${aws_api_gateway_deployment.prod.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.prod.stage_name}"
}
