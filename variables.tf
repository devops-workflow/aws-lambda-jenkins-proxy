variable "region" {
  default = "us-west-2"
}
variable "env" {
  description = "Deploy environment"
  default     = "one"
}

variable "headers" {
  description = "HTTP Header"
  default     = "[\"Content-Type\"]"
}
variable "jenkins_pswd" {
  description = "Login password for Jenkins server"
}

variable "jenkins_user" {
  description = "Login user for Jenkins server"
}

variable "jenkins_host" {
  description = "Jenkins server to trigger jobs on"
}

variable "api_gtwy_name" {
  description = "Name of the API gateway"
  default     = "jenkins-trigger"
}
variable "lambda_name" {
  description = "Name of the Lambda function"
  default     = "jenkins-trigger"
}
