[![CircleCI](https://circleci.com/gh/devops-workflow/aws-lambda-jenkins-proxy.svg?style=svg)](https://circleci.com/gh/devops-workflow/aws-lambda-jenkins-proxy)

This was done to allow CircleCI jobs trigger Jenkins jobs on a private Jenkins server

Workflow:
CircleCI -> AWS API Gateway -> AWS Lambda -> Jenkins
