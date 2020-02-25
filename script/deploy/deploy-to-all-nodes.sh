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

if [ ! -w "${PWD}/log" ]; then
  echo; echo "$(date): [ERROR] '${PWD}/log' directoy does not exist or is not writable"; echo
  exit 1
fi

# Boilerplate logging scheme
mkdir -p "${PWD}/log"
LOG=$(date +"${PWD}/log/junction-deploy_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

function log_info {
  echo "$(date): [INFO] ${1}" | ${LOGIT}
}

if [ "$(./script/deploy/_is_deploy_necessary.sh)" == "true" ]; then

  log_info "Delegating deploy to Capistrano..."

  ./script/deploy/_invoke-capistrano.sh

else

  log_info "No deployment necessary. Requested WAR file is already running on ${HOSTNAME}."

fi

log_info "Done."

exit 0
