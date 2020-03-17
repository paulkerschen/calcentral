#!/bin/bash

######################################################
#
# Download and deploy the "calcentral.knob"
#
######################################################

# Abort immediately if a command fails
set -e

# Boilerplate logging scheme
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

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

# Local properties file
deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"
deployment_summary_file="${HOME}/.calcentral_config/.deployment-summary-$(hostname -s)"

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && . "${HOME}/.rvm/scripts/rvm"
source .rvmrc

# Update source tree (from which these scripts run)
# The calcentral.knob file will be pulled from S3 bucket in AWS
git_branch=$(getDeployProperty 'junction.git.branch')
git_remote=$(getDeployProperty 'junction.git.remote')
log_info "========================================="
log_info "Updating Junction source code from: ${git_remote}, branch: ${git_branch}"

git fetch "${git_remote}" 2>&1 | ${LOGIT}
git fetch -t "${git_remote}" 2>&1 | ${LOGIT}
git reset --hard HEAD 2>&1 | ${LOGIT}
git checkout -qf "${git_remote}/${git_branch}" 2>&1 | ${LOGIT}

log_info "Last commit in source tree:"
git log -1 | ${LOGIT}

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
log_info "Stopping Junction..."

./script/stop-torquebox.sh

# Download the proper knob file
knob_file_id=$(./script/deploy/_get-knob-file-id.sh)
./script/deploy/_download-knob-file.sh "${knob_file_id}"

# Move the knob file into the new deploy directory
rm -rf deploy
mkdir deploy
mv ./calcentral.knob ./deploy
cd deploy || exit 1

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}

log_info "Unzipping knob: ${git_branch}/${knob_file_id}/calcentral.knob"

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

# Keep a record of what was deployed
echo "${knob_file_id}" > "${deployment_summary_file}"

log_info "${HOSTNAME} deployment complete."

echo | ${LOGIT}

exit 0
