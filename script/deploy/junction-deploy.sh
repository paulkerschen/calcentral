#!/bin/bash

##################################################################
#
# Kick off a Junction deploy
#
# Note: This script is intended for non-production environments.
#
##################################################################

# Abort immediately if a command fails
set -e

mkdir -p "${PWD}/log"
LOG=$(date +"${PWD}/log/junction-deploy_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

echo "$(date): [INFO] Begin!" | ${LOGIT}

deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"
deploy_tmp_dir="${PWD}/.junction-deploy-tmp-dir"

if [ ! -f "${deploy_properties}" ]; then
  echo "$(date): [ERROR] Missing properties file: ${deploy_properties}" | ${LOGIT}
  exit 1
fi

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

# Get feature flag setting. Is the new S3-based deployment strategy enabled?
feature_flag_s3_deploy=$(getDeployProperty 'feature.flag.s3.deploy' | awk '{print tolower($0)}')
feature_flag_s3_deploy="$(echo -e "${feature_flag_s3_deploy}" | tr -d '[:space:]')"

if [ "${feature_flag_s3_deploy}" != 'true' ]; then
  echo "$(date): [ERROR] The 'feature.flag.s3.deploy' property is not 'true'. Exiting deploy script." | ${LOGIT}
  exit 1
fi

echo "$(date): [INFO] Create temporary deploy dir: ${deploy_working_dir}" | ${LOGIT}
rm -Rf "${deploy_tmp_dir:?}/*"
deploy_working_dir="${deploy_tmp_dir}/$(date -u +%Y%m%d_%H%M%SZ)"

mkdir -p "${deploy_working_dir:?}"
cd "${deploy_working_dir}" || exit 1

git_remote=$(getDeployProperty 'junction.git.remote')
git_branch=$(getDeployProperty 'junction.git.branch')
echo "$(date): [INFO] Checkout branch '${git_branch}' from github.com/ets-berkeley-edu/calcentral" | ${LOGIT}

git clone git://github.com/ets-berkeley-edu/calcentral.git
cd calcentral
git checkout "${git_remote}/${git_branch}"

echo "$(date): [INFO] Execute 'calcentral/script/calcentral-update.sh'" | ${LOGIT}
./script/calcentral-update.sh

echo "$(date): [INFO] Done." | ${LOGIT}

exit 0
