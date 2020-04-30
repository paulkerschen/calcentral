#!/bin/bash

######################################################
#
# CalCentral database migration and cluster updates
#
######################################################

LOG=$(date +"${PWD}/log/start-stop_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"
VERSION=${1}

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

if [ -z "${1}" ]; then
  # Default db version is the latest one in our code tree
  if [ ! -d "db/migrate" ]
  then
    echo "$(date): ERROR: No database version specified!" | ${LOGIT}
    exit 1
  fi
  VERSION=$(/bin/ls db/migrate/ | awk -F _ '{print $1}' | sort | tail -1)
fi

export RAILS_ENV=${RAILS_ENV:-production}
export LOGGER_STDOUT=only
export JRUBY_OPTS="--dev"

LOG_DIR=${CALCENTRAL_LOG_DIR:=$(pwd)"/log"}
export CALCENTRAL_LOG_DIR=${LOG_DIR}

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"
source .rvmrc

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
echo "$(date): Database migration CalCentral on app node: $(hostname -s)" | ${LOGIT}

echo | ${LOGIT}
echo "$(date): rake db:migrate VERSION=${VERSION} RAILS_ENV=${RAILS_ENV} ..." | ${LOGIT}

bundle exec rake db:migrate VERSION="${VERSION}" RAILS_ENV="${RAILS_ENV}" |& ${LOGIT}

exit 0
