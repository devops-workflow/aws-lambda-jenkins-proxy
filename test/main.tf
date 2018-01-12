
module "lambda" {
  source        = "../"
  jenkins_host  = "${var.jenkins_host}"
  jenkins_user  = "${var.jenkins_user}"
  jenkins_pswd  = "${var.jenkins_pswd}"
}
