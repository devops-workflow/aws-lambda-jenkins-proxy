#!/bin/bash
#
# Trigger Jenkins job via AWS API gateway from CircleCi
#
# Uses CircleCI variables and variables from a CircleCI context
# Variables defined in context:
#   JENKINS_API_KEY, JENKINS_URL, JENKINS_JOB_TOKEN,
#   JENKINS_BUILD_CAUSE
# CircleCI Doc:
#   https://circleci.com/docs/2.0/env-vars/
#   https://circleci.com/docs/1.0/environment-variables/

# TODO:
#   Add git ref (CIRCLE_SHA1, CIRCLE_TAG), build number (CIRCLE_BUILD_NUM, CIRCLE_PREVIOUS_BUILD_NUM)
#   CIRCLE_STAGE job that is running
#   CircleCI can transfer data between jobs with workspaces
namespace=$1

if [ "${CIRCLECI}" != 'true' ]; then
  echo "ERROR: Not running under CircleCI"
  exit 1
fi
if [ "${CIRCLE_BRANCH}" == "master" ]; then
  repoBaseURL="${CIRCLE_REPOSITORY_URL%.*}"
  # Why not CIRCLE_PROJECT_REPONAME ?
  repo="${repoBaseURL##*/}"
  job_name="${namespace}+${repo}+CI+Analytics+CircleCI"
  build_cause="${JENKINS_BUILD_CAUSE}%20by%20${CIRCLE_USERNAME}"
  if [ -n "${BUILD_NUMS}" ]; then
    BuildNums="${BUILD_NUMS}"
  elif [ "${CIRCLE_STAGE}" == "ci" -o "${CIRCLE_STAGE}" == "Jenkins" ]; then
    BuildNums="${CIRCLE_PREVIOUS_BUILD_NUM}"
  else
    BuildNums="${CIRCLE_BUILD_NUM}"
  fi
  params="&ORG=${CIRCLE_PROJECT_USERNAME}&PROJECT=${CIRCLE_PROJECT_REPONAME}&GIT_REF=${CIRCLE_SHA1}&BUILD_NUMS=${BuildNums}"
  echo "INFO: Triggering Jenkins job: ${job_name}"
  echo "INFO: Params: ${params}"
  curl -H "x-api-key: ${JENKINS_API_KEY}" "${JENKINS_URL}${job_name}/${JENKINS_JOB_TOKEN}/${build_cause}?${params}"
fi


#CIRCLE_JOB - Job Name
#CIRCLE_TAG
#CIRCLE_STAGE
