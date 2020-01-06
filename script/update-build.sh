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
JUNCTION_DEPLOY_PROPERTIES="${HOME}/.calcentral_config/junction-deploy.properties"

if [ ! -f "${DEFAULT_DEPLOY_PROPERTIES}" ]; then
  echo "$(date): [ERROR] Missing properties file: ${DEFAULT_DEPLOY_PROPERTIES}" | ${LOGIT}
  exit 1
fi

if [ ! -f "${JUNCTION_DEPLOY_PROPERTIES}" ]; then
  echo "$(date): [ERROR] Missing properties file: ${JUNCTION_DEPLOY_PROPERTIES}" | ${LOGIT}
  exit 1
fi

function getDeployProperty {
  # Default properties file
  PROPERTIES="${DEFAULT_DEPLOY_PROPERTIES}"

  if [ "$(grep -c "^${1}=" "${JUNCTION_DEPLOY_PROPERTIES}")" -ne '0' ]; then
    # If value found in custom properties file then use it.
    PROPERTIES="${JUNCTION_DEPLOY_PROPERTIES}"
  fi

  grep "^${1}=" "${PROPERTIES}" | cut -d'=' -f2
}

# The calcentral.knob file will be pulled from S3 bucket in AWS
aws_access_key_id=$(getDeployProperty 'aws.access.key')
aws_secret_access_key=$(getDeployProperty 'aws.secret.access')
aws_s3_bucket=$(getDeployProperty 'aws.s3.bucket')
junction_git_branch=$(getDeployProperty 'junction.git.branch')
junction_git_remote=$(getDeployProperty 'junction.git.remote')

# Get feature flag setting. Is the new S3-based deployment strategy enabled?
FEATURE_FLAG_S3_DEPLOY=$(getDeployProperty 'feature.flag.s3.deploy' | awk '{print tolower($0)}')
FEATURE_FLAG_S3_DEPLOY="$(echo -e "${FEATURE_FLAG_S3_DEPLOY}" | tr -d '[:space:]')"

if [ "${FEATURE_FLAG_S3_DEPLOY}" == 'true' ]; then

  # We will abort if no update is necessary.
  # I.e., the latest knob file in S3 is identical to what is running in this enviroment.
  junction_knob_id=$(getDeployProperty 'junction.knob.id')

  if [ -z "${junction_knob_id}" ]; then
    echo "$(date): [ERROR] The 'junction.knob.id' config is blank or missing." | ${LOGIT}
    exit 1
  fi

  if [ "${junction_knob_id}" == 'latest' ]; then
    # In non-production environments, pull the latest knob file from AWS S3 bucket.
    # EXAMPLE of knob file S3 path: s3://rtl-travis-junction/master/20191230_235901Z/calcentral.knob
    KNOB_FILE_ID=$(aws s3 ls "s3://${aws_s3_bucket}/${junction_git_branch}/" --profile travis | sort --reverse | head -1)
    # shellcheck disable=SC2001
    KNOB_FILE_ID=$(echo "${KNOB_FILE_ID}" | sed 's/^.* \(2.*Z\).*/\1/')

  else
    # In production, the version of knob file will be specified in JUNCTION_DEPLOY_PROPERTIES (see file info above)
    KNOB_FILE_ID="${junction_knob_id}"
  fi

  if [ -f "{JUNCTION_KNOB_FILE_INFO}" ] && [ "$(grep -c "${KNOB_FILE_ID}" "${JUNCTION_KNOB_FILE_INFO}")" -ne '0' ]; then
    echo "$(date): [INFO] No update necessary. The latest knob file in S3 is identical to what is currently running in this enviroment." | ${LOGIT}
    exit 0
  fi
fi

cd $( dirname "${BASH_SOURCE[0]}" )/..

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && . "${HOME}/.rvm/scripts/rvm"
source .rvmrc

# Update source tree (from which these scripts run)
echo "$(date): [INFO] =========================================" | ${LOGIT}
echo "$(date): [INFO] Updating Junction source code from: ${junction_git_remote}, branch: ${junction_git_branch}" | ${LOGIT}

git fetch "${junction_git_remote}" 2>&1 | ${LOGIT}
git fetch -t "${junction_git_remote}" 2>&1 | ${LOGIT}
git reset --hard HEAD 2>&1 | ${LOGIT}
git checkout -qf "${junction_git_branch}" 2>&1 | ${LOGIT}

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

  if [[ -z "${aws_access_key_id}" || -z "${aws_secret_access_key}" || -z "${aws_s3_bucket}" || -z "${junction_git_branch}" ]]; then
    echo "$(date): [ERROR] One or more required settings not found in ${JUNCTION_DEPLOY_PROPERTIES}."
    exit 1
  fi
  # Download from S3
  export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
  export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
  s3_path="s3://${aws_s3_bucket}/${junction_git_branch}/${KNOB_FILE_ID}/calcentral.knob"

  echo "$(date): [INFO] Fetching new calcentral.knob from ${s3_path}" | ${LOGIT}
  aws s3 cp "${s3_path}" .

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

# Keep a record of what was deployed
echo "${KNOB_FILE_ID}" > "${JUNCTION_KNOB_FILE_INFO}"

echo "$(date): [INFO] Congratulations, deployment complete." | ${LOGIT}

echo | ${LOGIT}

exit 0
