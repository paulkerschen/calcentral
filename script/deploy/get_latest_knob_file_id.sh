#!/bin/bash

######################################################
#
# Get unique id associated with the latest 'calcentral.knob' in AWS S3.
# For example, the id of the latest build (master branch) is in s3://rtl-travis-junction/master/latest.txt
#
######################################################

deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"

if [ ! -f "${deploy_properties}" ]; then
  echo "$(date): [ERROR] Missing properties file: ${deploy_properties}" | ${LOGIT}
  exit 1
fi

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

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

latest_knob_file_id=$(head -1 latest.txt)
latest_knob_file_id=${latest_knob_file_id#"/${git_branch}/"}
latest_knob_file_id=${latest_knob_file_id%"/calcentral.knob"}

echo "${latest_knob_file_id}"

exit 0
