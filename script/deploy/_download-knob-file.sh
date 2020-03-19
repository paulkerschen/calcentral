#!/bin/bash

##################################################################
#
# Download knob file from AWS S3 bucket.
#
##################################################################

# Abort immediately if a command fails
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

# One required argument
[ $# -eq 0 ] && { echo "$(date): [ERROR] Usage: ${0} \${knob_file_id}"; exit 1; }

knob_file_id="${1}"

# Boilerplate logging scheme
LOG=$(date +"${PWD}/log/junction-deploy_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

function log_error {
  echo | ${LOGIT}
  echo "$(date): [ERROR] ${1}" | ${LOGIT}
  echo | ${LOGIT}
}

function log_info {
  echo "$(date): [INFO] ${1}" | ${LOGIT}
}

# Local properties file
deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

# The calcentral.knob file will be pulled from S3 bucket in AWS
aws_access_key_id=$(getDeployProperty 'aws.access.key')
aws_secret_access_key=$(getDeployProperty 'aws.secret.access')
aws_s3_bucket=$(getDeployProperty 'aws.s3.bucket')
git_branch=$(getDeployProperty 'junction.git.branch')

# Used by curl when downloading files from AWS S3
date_rfc_2822=$(date -R)

if [[ -z "${aws_access_key_id}" || -z "${aws_secret_access_key}" || -z "${aws_s3_bucket}" || -z "${git_branch}" ]]; then
  log_error "One or more required settings not found in ${deploy_properties}."
  exit 1
fi

content_type="application/x-compressed-tar"
s3_path="${git_branch}/${knob_file_id}/calcentral.knob"
signature=$(echo -en "GET\n\n${content_type}\n${date_rfc_2822}\n/${aws_s3_bucket}/${s3_path}" | openssl sha1 -hmac ${aws_secret_access_key} -binary | base64)

# Download from S3
log_info "Fetching new calcentral.knob from ${s3_path}"

curl -sS \
     -H "Host: ${aws_s3_bucket}.s3.amazonaws.com" \
     -H "Date: ${date_rfc_2822}" \
     -H "Content-Type: ${content_type}" \
     -H "Authorization: AWS ${aws_access_key_id}:${signature}" \
     "https://${aws_s3_bucket}.s3.amazonaws.com/${s3_path}" -o calcentral.knob > /dev/null

exit 0