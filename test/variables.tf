variable "region" {
  default = "us-west-2"
}

variable "env" {
  description = "Deploy environment"
  default     = "one"
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
