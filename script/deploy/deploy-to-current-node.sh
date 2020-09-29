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

if [ ! -w "${PWD}/log" ]; then
  echo; echo "$(date): [ERROR] '${PWD}/log' directory does not exist or is not writable"; echo
  exit 1
fi

# Boilerplate logging scheme
mkdir -p "${PWD}/log"
LOG=$(date +"${PWD}/log/junction-deploy_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

DOC_ROOT="/var/www/html/junction"

function log_error {
  echo | ${LOGIT}
  echo "$(date): [ERROR] ${1}" | ${LOGIT}
  echo | ${LOGIT}
}

function log_info {
  echo "$(date): [INFO] ${1}" | ${LOGIT}
}

touch "${DOC_ROOT}/calcentral-in-maintenance"

./script/deploy/_download-war-for-tomcat.sh || { log_error "download-war-for-tomcat failed"; exit 1; }

if [[ "$(uname -n)" = *-01\.ist.berkeley.edu ]]; then
  ./script/migrate.sh
fi

log_info "Done."

exit 0
