#!/bin/bash

######################################################
#
# Roll back CalCentral database migration
#
######################################################

cd $( dirname "${BASH_SOURCE[0]}" )/..

LAST_VERSION=$(cat versions/previous_release_db_schema.txt)

LOG=$(date +"${PWD}/log/start-stop_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
echo "$(date): Downgrading CalCentral to ${LAST_VERSION} on app node: $(hostname -s)" | ${LOGIT}

sudo systemctl stop tomcat9@junction

./script/migrate.sh ${LAST_VERSION}

exit 0
