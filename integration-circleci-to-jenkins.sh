#!/bin/bash
#
# Trigger Jenkins job via AWS API gateway from CircleCi
#
# Uses CircleCI variables and variables from a CirclCI context
# Variables defined in context:
#   JENKINS_API_KEY, JENKINS_URL, JENKINS_JOB_TOKEN,
#   JENKINS_BUILD_CAUSE
namespace=$1

if [ "${CIRCLECI}" != 'true' ]; then
  echo "ERROR: Not running under CircleCI"
  exit 1
fi
if [ "${CIRCLE_BRANCH}" == "master" ]; then
  repoBaseURL="${CIRCLE_REPOSITORY_URL%.*}"
  repo="${repoBaseURL##*/}"
  job_name="${namespace}+${repo}+CI+Package_Docker"
  build_cause="${JENKINS_BUILD_CAUSE}%20by%20${CIRCLE_USERNAME}"
  curl -H "x-api-key: ${JENKINS_API_KEY}" ${JENKINS_URL}${job_name}/${JENKINS_JOB_TOKEN}/${build_cause}
fi
