#!/bin/bash
BUCKET="wiser-$ENV-tf"
echo "Using bucket=$BUCKET"
terraform init --upgrade\
     -backend-config "bucket=$BUCKET" \
     -backend-config "region=us-west-2" \
     -backend-config "key=services-infra/aws-lambda-jenkins-proxy.tfstate" \
     -backend-config "encrypt=true"
