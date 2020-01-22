#!/bin/bash

######################################################
#
# This script delegates to Capistrano.
#
######################################################

# Abort immediately if a command fails
set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

LOG=$(date +"${PWD}/log/update-build_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"

source .rvmrc

export RAILS_ENV=${RAILS_ENV:-production}
export LOGGER_STDOUT=only
export JRUBY_OPTS="--dev"

echo "------------------------------------------"
echo "$(date): [INFO] Deploying Junction on all app nodes with Capistrano." | ${LOGIT}

cap -l STDOUT deploy_to_all_servers:s3_artifact || { echo "$(date): [ERROR] Capistrano deploy failed" | ${LOGIT}; exit 1; }

exit 0
