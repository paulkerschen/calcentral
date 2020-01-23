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

function log_info {
  echo "$(date): [INFO] ${1}" | ${LOGIT}
}

log_info "Delegating deploy to Capistrano..."

./script/deploy/_invoke-capistrano.sh

log_info "Done."

exit 0
