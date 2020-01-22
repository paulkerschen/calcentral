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

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

# Boilerplate logging scheme
mkdir -p "${PWD}/log"
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
deploy_tmp_dir="${PWD}/.junction-deploy-tmp-dir"

if [ ! -f "${deploy_properties}" ]; then
  log_error "Missing properties file: ${deploy_properties}"
  exit 1
fi

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

log_info "Begin!" | ${LOGIT}

log_info "Create temporary deploy dir: ${deploy_working_dir}"

rm -Rf "${deploy_tmp_dir:?}/*"
deploy_working_dir="${deploy_tmp_dir}/$(date -u +%Y%m%d_%H%M%SZ)"

mkdir -p "${deploy_working_dir:?}"
cd "${deploy_working_dir}" || exit 1

git_remote=$(getDeployProperty 'junction.git.remote')
git_branch=$(getDeployProperty 'junction.git.branch')

log_info "Checkout branch '${git_branch}' from github.com/ets-berkeley-edu/calcentral"

git clone git://github.com/ets-berkeley-edu/calcentral.git
cd calcentral
git checkout "${git_remote}/${git_branch}"

log_info "Delegating deploy to Capistrano..."

./script/deploy/_invoke-capistrano.sh

log_info "Done."

exit 0
