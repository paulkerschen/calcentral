#!/bin/bash

######################################################
#
# Download and deploy the "calcentral.knob"
#
######################################################

LOG=$(date +"${PWD}/log/update-build_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

echo | ${LOGIT}

DEFAULT_DEPLOY_PROPERTIES="${PWD}/config/settings/junction-deploy.properties"
DEPLOY_PROPERTIES="${HOME}/.calcentral_config/junction-deploy.properties"
DEPLOYMENT_SUMMARY_FILE="${HOME}/.calcentral_config/.junction-deployment-summary"

if [ ! -f "${DEFAULT_DEPLOY_PROPERTIES}" ]; then
  echo "$(date): [ERROR] Missing properties file: ${DEFAULT_DEPLOY_PROPERTIES}" | ${LOGIT}
  exit 1
fi

if [ ! -f "${DEPLOY_PROPERTIES}" ]; then
  echo "$(date): [ERROR] Missing properties file: ${DEPLOY_PROPERTIES}" | ${LOGIT}
  exit 1
fi

function getDeployProperty {
  # Default properties file
  PROPERTIES="${DEFAULT_DEPLOY_PROPERTIES}"

  if [ "$(grep -c "^${1}=" "${DEPLOY_PROPERTIES}")" -ne '0' ]; then
    # If value found in custom properties file then use it.
    PROPERTIES="${DEPLOY_PROPERTIES}"
  fi

  grep "^${1}=" "${PROPERTIES}" | cut -d'=' -f2
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
FEATURE_FLAG_S3_DEPLOY=$(getDeployProperty 'feature.flag.s3.deploy' | awk '{print tolower($0)}')
FEATURE_FLAG_S3_DEPLOY="$(echo -e "${FEATURE_FLAG_S3_DEPLOY}" | tr -d '[:space:]')"

echo "$(date): [INFO] FEATURE_FLAG_S3_DEPLOY='${FEATURE_FLAG_S3_DEPLOY}' " | ${LOGIT}

if [ "${FEATURE_FLAG_S3_DEPLOY}" == 'true' ]; then

  if [[ -z "${aws_access_key_id}" || -z "${aws_secret_access_key}" || -z "${aws_s3_bucket}" || -z "${git_branch}" ]]; then
    echo "$(date): [ERROR] One or more required settings not found in ${DEPLOY_PROPERTIES}."
    exit 1
  fi

  # We will abort if no update is necessary.
  # I.e., the latest knob file in S3 is identical to what is running in this enviroment.
  junction_knob_id=$(getDeployProperty 'junction.knob.id')

  if [ -z "${junction_knob_id}" ]; then
    echo "$(date): [ERROR] The 'junction.knob.id' config is blank or missing." | ${LOGIT}
    exit 1
  fi

  if [ "${junction_knob_id}" == 'latest' ]; then

    content_type="text/plain"
    s3_path="${git_branch}/latest.txt"
    signature=$(echo -en "GET\n\n${content_type}\n${date_rfc_2822}\n/${aws_s3_bucket}/${s3_path}" | openssl sha1 -hmac ${aws_secret_access_key} -binary | base64)

    curl -H "Host: ${aws_s3_bucket}.s3.amazonaws.com" \
         -H "Date: ${date_rfc_2822}" \
         -H "Content-Type: ${content_type}" \
         -H "Authorization: AWS ${aws_access_key_id}:${signature}" \
         "https://${aws_s3_bucket}.s3.amazonaws.com/${s3_path}" -o latest.txt

    latest_knob_file_id=$(head -1 latest.txt)
    latest_knob_file_id=${latest_knob_file_id#"/${git_branch}/"}
    latest_knob_file_id=${latest_knob_file_id%"/calcentral.knob"}

    if [ -z "${latest_knob_file_id}" ]; then
      echo "$(date): [ERROR] The file s3://${aws_s3_bucket}/${git_branch}/latest.txt has bad data."  | ${LOGIT}
      exit 1
    else
      knob_file_id="${latest_knob_file_id}"
    fi

    echo "$(date): [INFO] The latest knob file in S3 is ${git_branch}/${knob_file_id}/calcentral.knob." | ${LOGIT}

  else
    # In production, the version of knob file will be specified in DEPLOY_PROPERTIES (see file info above)
    knob_file_id="${junction_knob_id}"
  fi

  if [ -f "{DEPLOYMENT_SUMMARY_FILE}" ] && [ "$(grep -c "${latest_knob_file_id}" "${DEPLOYMENT_SUMMARY_FILE}")" -ne '0' ]; then
    echo "$(date): [INFO] No update necessary. The latest knob file in S3 is identical to what is currently running in this enviroment." | ${LOGIT}
    exit 0
  else
    echo "$(date): [INFO] From AWS S3, we will deploy '${knob_file_id}/calcentral.knob'" | ${LOGIT}
  fi
fi

cd $( dirname "${BASH_SOURCE[0]}" )/..

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && . "${HOME}/.rvm/scripts/rvm"
source .rvmrc

# Update source tree (from which these scripts run)
echo "$(date): [INFO] =========================================" | ${LOGIT}
echo "$(date): [INFO] Updating Junction source code from: ${git_remote}, branch: ${git_branch}" | ${LOGIT}

git fetch "${git_remote}" 2>&1 | ${LOGIT}
git fetch -t "${git_remote}" 2>&1 | ${LOGIT}
git reset --hard HEAD 2>&1 | ${LOGIT}
git checkout -qf "${git_branch}" 2>&1 | ${LOGIT}

echo "$(date): [INFO] Last commit in source tree:" | ${LOGIT}
git log -1 | ${LOGIT}


echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
echo "$(date): [INFO] Stopping Junction..." | ${LOGIT}

./script/stop-torquebox.sh

rm -rf deploy
mkdir deploy
cd deploy

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}

if [ "${FEATURE_FLAG_S3_DEPLOY}" == 'true' ]; then

  content_type="application/x-compressed-tar"
  s3_path="${git_branch}/${knob_file_id}/calcentral.knob"
  signature=$(echo -en "GET\n\n${content_type}\n${date_rfc_2822}\n/${aws_s3_bucket}/${s3_path}" | openssl sha1 -hmac ${aws_secret_access_key} -binary | base64)

  # Download from S3
  echo "$(date): [INFO] Fetching new calcentral.knob from ${s3_path}" | ${LOGIT}

  curl -H "Host: ${aws_s3_bucket}.s3.amazonaws.com" \
       -H "Date: ${date_rfc_2822}" \
       -H "Content-Type: ${content_type}" \
       -H "Authorization: AWS ${aws_access_key_id}:${signature}" \
       "https://${aws_s3_bucket}.s3.amazonaws.com/${s3_path}" -o calcentral.knob

else
  echo "$(date): [INFO] Fetching new calcentral.knob from ${WAR_URL}" | ${LOGIT}

  # Get calcentral.knob file from Bamboo (deprecated deployment strategy)
  WAR_URL=${WAR_URL:="https://bamboo.media.berkeley.edu/bamboo/browse/MYB-MVPWAR/latest/artifact/JOB1/warfile/calcentral.knob"}
  curl -k -s ${WAR_URL} > calcentral.knob
fi

echo "$(date): [INFO] Unzipping knob..." | ${LOGIT}

jar xf calcentral.knob

if [ ! -d "versions" ]; then
  echo "$(date): [ERROR] Missing or malformed calcentral.knob file!" | ${LOGIT}
  exit 1
fi
echo "$(date): [INFO] Last commit in calcentral.knob:" | ${LOGIT}
cat versions/git.txt | ${LOGIT}

# Fix permissions on files that need to be executable
chmod u+x ./script/*
chmod u+x ./vendor/bundle/jruby/2.3.0/bin/*
find ./vendor/bundle -name standalone.sh | xargs chmod u+x

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
echo "$(date): [INFO] Deploying new Junction knob..." | ${LOGIT}

bundle exec torquebox deploy calcentral.knob --env=production | ${LOGIT}

MAX_ASSET_AGE_IN_DAYS=${MAX_ASSET_AGE_IN_DAYS:="45"}
DOC_ROOT="/var/www/html/junction"

echo "$(date): [INFO] Copying assets into ${DOC_ROOT}" | ${LOGIT}
cp -Rvf public/assets ${DOC_ROOT} | ${LOGIT}

echo "$(date): [INFO] Deleting old assets from ${DOC_ROOT}/assets" | ${LOGIT}
find ${DOC_ROOT}/assets -type f -mtime +${MAX_ASSET_AGE_IN_DAYS} -delete | ${LOGIT}

echo "$(date): [INFO] Copying bCourses static files into ${DOC_ROOT}" | ${LOGIT}
cp -Rvf public/canvas ${DOC_ROOT} | ${LOGIT}

echo "$(date): [INFO] Copying OAuth static files into ${DOC_ROOT}" | ${LOGIT}
cp -Rvf public/oauth ${DOC_ROOT} | ${LOGIT}

if [ "${FEATURE_FLAG_S3_DEPLOY}" == 'true' ]; then
  # Keep a record of what was deployed
  echo "${knob_file_id}" > "${DEPLOYMENT_SUMMARY_FILE}"
fi

echo "$(date): [INFO] Congratulations, deployment complete." | ${LOGIT}

echo | ${LOGIT}

exit 0
