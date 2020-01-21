#!/bin/bash

######################################################
#
# Download and deploy the "calcentral.knob"
#
######################################################

LOG=$(date +"${PWD}/log/update-build_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

function log_error {
  echo | ${LOGIT}
  echo "$(date): [ERROR] ${1}" | ${LOGIT}
  echo | ${LOGIT}
}

function log_info {
  echo "$(date): [INFO] ${1}" | ${LOGIT}
}

echo | ${LOGIT}

deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"
deployment_summary_file="${HOME}/.calcentral_config/.junction-deployment-summary"

if [ ! -f "${deploy_properties}" ]; then
  log_error "Missing properties file: ${deploy_properties}"
  exit 1
fi

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

# The calcentral.knob file will be pulled from S3 bucket in AWS
aws_access_key_id=$(getDeployProperty 'aws.access.key')
aws_secret_access_key=$(getDeployProperty 'aws.secret.access')
aws_s3_bucket=$(getDeployProperty 'aws.s3.bucket')
git_branch=$(getDeployProperty 'junction.git.branch')
git_remote=$(getDeployProperty 'junction.git.remote')

# Used by curl when downloading files from AWS S3
date_rfc_2822=$(date -R)

# Get feature flag setting. Is the new S3-based deployment strategy enabled?
feature_flag_s3_deploy=$(getDeployProperty 'feature.flag.s3.deploy' | awk '{print tolower($0)}')
feature_flag_s3_deploy="$(echo -e "${feature_flag_s3_deploy}" | tr -d '[:space:]')"

log_info "feature_flag_s3_deploy='${feature_flag_s3_deploy}'"

if [ "${feature_flag_s3_deploy}" == 'true' ]; then

  if [[ -z "${aws_access_key_id}" || -z "${aws_secret_access_key}" || -z "${aws_s3_bucket}" || -z "${git_branch}" ]]; then
    log_error "One or more required settings not found in ${deploy_properties}."
    exit 1
  fi

  # We will abort if no update is necessary.
  # I.e., the latest knob file in S3 is identical to what is running in this enviroment.
  junction_knob_id=$(getDeployProperty 'junction.knob.id')

  if [ -z "${junction_knob_id}" ]; then
    log_error "The 'junction.knob.id' config is blank or missing."
    exit 1
  fi

  if [ "${junction_knob_id}" == 'latest' ]; then

    latest_knob_file_id=$(./script/deploy/get_latest_knob_file_id.sh)

    if [ -z "${latest_knob_file_id}" ]; then
      log_error "The file s3://${aws_s3_bucket}/${git_branch}/latest.txt has bad data."
      exit 1
    else
      knob_file_id="${latest_knob_file_id}"
    fi

    log_info "The latest knob file in S3 is ${git_branch}/${knob_file_id}/calcentral.knob."

  else
    # In production, the version of knob file will be specified in deploy_properties (see file info above)
    knob_file_id="${junction_knob_id}"
  fi

  if [ -f "{deployment_summary_file}" ] && [ "$(grep -c "${latest_knob_file_id}" "${deployment_summary_file}")" -ne '0' ]; then
    log_info "No update necessary. The latest knob file in S3 is identical to what is currently running in this enviroment."
    exit 0
  else
    log_info "From AWS S3, we will deploy '${knob_file_id}/calcentral.knob'"
  fi
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && . "${HOME}/.rvm/scripts/rvm"
source .rvmrc

# Update source tree (from which these scripts run)
log_info "========================================="
log_info "Updating Junction source code from: ${git_remote}, branch: ${git_branch}"

git fetch "${git_remote}" 2>&1 | ${LOGIT}
git fetch -t "${git_remote}" 2>&1 | ${LOGIT}
git reset --hard HEAD 2>&1 | ${LOGIT}
git checkout -qf "${git_branch}" 2>&1 | ${LOGIT}

log_info "Last commit in source tree:"
git log -1 | ${LOGIT}


echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
log_info "Stopping Junction..."

./script/stop-torquebox.sh

rm -rf deploy
mkdir deploy
cd deploy || exit 1

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}

if [ "${feature_flag_s3_deploy}" == 'true' ]; then

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

else
  log_info "Fetching new calcentral.knob from ${WAR_URL}"

  # Get calcentral.knob file from Bamboo (deprecated deployment strategy)
  WAR_URL=${WAR_URL:="https://bamboo.media.berkeley.edu/bamboo/browse/MYB-MVPWAR/latest/artifact/JOB1/warfile/calcentral.knob"}
  curl -k -s ${WAR_URL} > calcentral.knob
fi

log_info "Unzipping knob..."

jar xf calcentral.knob

if [ ! -d "versions" ]; then
  log_error "Missing or malformed calcentral.knob file!"
  exit 1
fi
log_info "Last commit in calcentral.knob:"
cat versions/git.txt | ${LOGIT}

# Fix permissions on files that need to be executable
chmod u+x ./script/*
chmod u+x ./vendor/bundle/jruby/2.3.0/bin/*
find ./vendor/bundle -name standalone.sh | xargs chmod u+x

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
log_info "Deploying new Junction knob..."

bundle exec torquebox deploy calcentral.knob --env=production | ${LOGIT}

MAX_ASSET_AGE_IN_DAYS=${MAX_ASSET_AGE_IN_DAYS:="45"}
DOC_ROOT="/var/www/html/junction"

log_info "Copying assets into ${DOC_ROOT}"
cp -Rvf public/assets ${DOC_ROOT} | ${LOGIT}

log_info "Deleting old assets from ${DOC_ROOT}/assets"
find ${DOC_ROOT}/assets -type f -mtime +${MAX_ASSET_AGE_IN_DAYS} -delete | ${LOGIT}

log_info "Copying bCourses static files into ${DOC_ROOT}"
cp -Rvf public/canvas ${DOC_ROOT} | ${LOGIT}

log_info "Copying OAuth static files into ${DOC_ROOT}"
cp -Rvf public/oauth ${DOC_ROOT} | ${LOGIT}

if [ "${feature_flag_s3_deploy}" == 'true' ]; then
  # Keep a record of what was deployed
  echo "${knob_file_id}" > "${deployment_summary_file}"
fi

log_info "Congratulations, deployment complete."

echo | ${LOGIT}

exit 0
