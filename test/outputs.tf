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
