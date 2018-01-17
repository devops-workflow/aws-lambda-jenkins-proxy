/*
output "whitelist_wiser_id" {
  description = "The ID of the security group"
  value       = "${module.public-whitelist.id}"
}
*/
output "security_group_ids" {
  value = "${module.lambda.security_group_ids}"
}
output "subnet_ids" {
  value = "${module.lambda.subnet_ids}"
}

output  "api_id" {
  description = "API Gateway ID"
  value       = "${module.lambda.api_id}"
}
output  "api_key_id" {
  description = "API Key ID"
  value       = "${module.lambda.api_key_id}"
}
output  "api_key_value" {
  description = "API Key value"
  value       = "${module.lambda.api_key_value}"
}

/*
output "dev_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}*/

output "prod_url" {
  value = "${module.lambda.prod_url}"
}
