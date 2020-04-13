#!/bin/bash

######################################################
#
# Download and deploy the junction.war file
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
deployment_summary_file="${HOME}/.calcentral_config/.junction-deployment-summary"

function getDeployProperty {
  grep "^${1}=" "${deploy_properties}" | cut -d'=' -f2
}

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && . "${HOME}/.rvm/scripts/rvm"
source .rvmrc

# Update source tree (from which these scripts run)
# The junction.war file will be pulled from S3 bucket in AWS
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

~/bin/tomcat9-junction.sh status | grep "is running"

tomreturn=$?

if [ $tomreturn -eq 0 ] ; then
   echo "$(date): Stopping Tomcat..." | ${LOGIT}
   ~/bin/tomcat9-junction.sh stop | ${LOGIT} 2>&1
else
   echo "WARNING: Tomcat not running. No shutdown attempted, will proceed with download" | ${LOGIT}
fi

# Download the proper WAR file
war_file_id=$(./script/deploy/_get-war-file-id.sh)
./script/deploy/_download-war-file.sh "${war_file_id}"

# For now at least, rename junction.war file to ROOT.war (to use default Tomcat ROOT location)
mv junction.war ${TOMCAT_DEPLOY}/ROOT.war | ${LOGIT}

log_info "${HOSTNAME} junction.war download complete."

exit 0
