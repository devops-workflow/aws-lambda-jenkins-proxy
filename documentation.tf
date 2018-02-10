//
// Document methods
//
resource "aws_api_gateway_documentation_part" "GetTrigger" {
  depends_on = [
    "aws_api_gateway_documentation_part.PathBuildCause",
  ]

  location {
    #name    = "BuildCause"
    type   = "METHOD"
    method = "GET"
    path   = "/{JobName}/{JobToken}/{BuildCause}"
  }

  properties  = "{\"description\":\"What caused this request to be triggered?\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

//
// Document URL path
//
resource "aws_api_gateway_documentation_part" "PathBuildCause" {
  depends_on = [
    "aws_api_gateway_documentation_part.PathJobToken",
  ]

  location {
    type   = "PATH_PARAMETER"
    name   = "BuildCause"
    method = "GET"
    path   = "/{JobName}/{JobToken}/{BuildCause}"
  }

  properties  = "{\"description\":\"What caused this request to be triggered?\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

resource "aws_api_gateway_documentation_part" "PathJobName" {
  location {
    type   = "PATH_PARAMETER"
    name   = "JobName"
    method = "GET"
    path   = "/{JobName}"
  }

  properties  = "{\"description\":\"Name of the Jenkins Job to trigger\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

resource "aws_api_gateway_documentation_part" "PathJobToken" {
  depends_on = [
    "aws_api_gateway_documentation_part.PathJobName",
  ]

  location {
    type   = "PATH_PARAMETER"
    name   = "JobToken"
    method = "GET"
    path   = "/{JobName}/{JobToken}"
  }

  properties  = "{\"description\":\"Jenkins Job Token for triggering the specified job\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

//
// Document query parameters
//
resource "aws_api_gateway_documentation_part" "QueryGitRef" {
  depends_on = [
    "aws_api_gateway_documentation_part.GetTrigger",
  ]

  location {
    type   = "QUERY_PARAMETER"
    name   = "GIT_REF"
    method = "GET"
    path   = "/{JobName}/{JobToken}/{BuildCause}"
  }

  properties  = "{\"description\":\"Git reference of build\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

resource "aws_api_gateway_documentation_part" "QueryBuildNums" {
  depends_on = [
    "aws_api_gateway_documentation_part.GetTrigger",
  ]

  location {
    type   = "QUERY_PARAMETER"
    name   = "BUILD_NUMS"
    method = "GET"
    path   = "/{JobName}/{JobToken}/{BuildCause}"
  }

  properties  = "{\"description\":\"Comma separated list of CIrcleCI build numbers to get artifacts from\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

resource "aws_api_gateway_documentation_part" "QueryOrg" {
  depends_on = [
    "aws_api_gateway_documentation_part.GetTrigger",
  ]

  location {
    type   = "QUERY_PARAMETER"
    name   = "ORG"
    method = "GET"
    path   = "/{JobName}/{JobToken}/{BuildCause}"
  }

  properties  = "{\"description\":\"GitHub organization or user where project repo is\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}

resource "aws_api_gateway_documentation_part" "QueryProject" {
  depends_on = [
    "aws_api_gateway_documentation_part.GetTrigger",
  ]

  location {
    type   = "QUERY_PARAMETER"
    name   = "PROJECT"
    method = "GET"
    path   = "/{JobName}/{JobToken}/{BuildCause}"
  }

  properties  = "{\"description\":\"GitHub project repo name\"}"
  rest_api_id = "${aws_api_gateway_rest_api.jenkins-trigger.id}"
}
