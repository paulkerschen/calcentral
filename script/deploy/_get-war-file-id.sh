#!/bin/bash

######################################################
#
# Get unique id associated with the latest 'junction.war' in AWS S3.
# For example, the id of the latest build (master branch) is in s3://rtl-travis-junction/master/latest.txt
#
# IMPORTANT: This script can write ONE AND ONLY ONE thing to stdout: ${knob_file_id}
#            Client that invokes this script is expecting only that value in return.
#
######################################################

# Abort immediately if a command fails
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

LOG=$(date +"${PWD}/log/update-build_%Y-%m-%d.log")

# Local properties file
deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

# We will abort if no update is necessary.
# I.e., the latest knob file in S3 is identical to what is running in this enviroment.
junction_war_id=$(getDeployProperty 'junction.war.id')

if [ -z "${junction_knob_id}" ]; then
  echo "$(date): [ERROR] The 'junction.war.id' config is blank or missing." > "${LOG}"
  exit 1
fi

if [ "${junction_knob_id}" == 'latest' ]; then

  aws_access_key_id=$(getDeployProperty 'aws.access.key')
  aws_secret_access_key=$(getDeployProperty 'aws.secret.access')
  aws_s3_bucket=$(getDeployProperty 'aws.s3.bucket')
  git_branch=$(getDeployProperty 'junction.git.branch')

  date_rfc_2822=$(date -R)
  content_type="text/plain"
  s3_path="${git_branch}/latest.txt"
  signature=$(echo -en "GET\n\n${content_type}\n${date_rfc_2822}\n/${aws_s3_bucket}/${s3_path}" | openssl sha1 -hmac ${aws_secret_access_key} -binary | base64)

  curl -sS \
       -H "Host: ${aws_s3_bucket}.s3.amazonaws.com" \
       -H "Date: ${date_rfc_2822}" \
       -H "Content-Type: ${content_type}" \
       -H "Authorization: AWS ${aws_access_key_id}:${signature}" \
       "https://${aws_s3_bucket}.s3.amazonaws.com/${s3_path}" -o latest.txt > /dev/null

  latest_war_file_id=$(head -1 latest.txt)
  latest_war_file_id=${latest_knob_file_id#"/${git_branch}/"}
  latest_war_file_id=${latest_knob_file_id%"/junction.war"}

  if [ -z "${latest_war_file_id}" ]; then
    echo "$(date): [ERROR] The file s3://${aws_s3_bucket}/${git_branch}/latest.txt has bad data." > "${LOG}"
    exit 1
  else
    war_file_id="${latest_war_file_id}"
  fi

else
  # In production, the version of WAR file will be specified in deploy_properties (see file info above)
  war_file_id="${junction_war_id}"
fi

echo "${war_file_id}"

exit 0
