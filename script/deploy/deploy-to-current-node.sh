#!/bin/bash

######################################################
#
# This script is intended for manual deploy in production.
# Ops will run it on each server in the cluster.
#
######################################################

# Abort immediately if a command fails
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

# Verify presence of local properties file
deploy_properties="${HOME}/.calcentral_config/junction-deploy.properties"

if [ ! -f "${deploy_properties}" ]; then
  log_error "Missing properties file: ${deploy_properties}"
  exit 1
fi

# Boilerplate logging scheme
mkdir -p "${PWD}/log"
LOG=$(date +"${PWD}/log/junction-deploy_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

function log_error {
  echo | ${LOGIT}
  echo "$(date): [ERROR] ${1}" | ${LOGIT}
  echo | ${LOGIT}
}

./script/init.d/calcentral maint

./script/deploy/_download-knob-for-torquebox.sh || { log_error "download-knob-for-torquebox failed"; exit 1; }

if [[ "$(uname -n)" = *-01\.ist.berkeley.edu ]]; then
  ./script/migrate.sh
fi

exit 0
