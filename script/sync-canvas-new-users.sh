#!/bin/bash
# Script to update all users within Canvas from People/Guest Oracle view

# Make sure the normal shell environment is in place, since it may not be
# when running as a cron job.
source "${HOME}/.bash_profile"

cd $( dirname "${BASH_SOURCE[0]}" )/..

LOG=$(date +"${PWD}/log/canvas_new_user_sync_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"
source .rvmrc

# Write heap-dump file to disk when HeapDumpOnOutOfMemoryError; mkdir will not complain if directory exists.
HEAP_DUMP_DIR="${HOME}/.calcentral_config/javadump/"
mkdir -p "${HEAP_DUMP_DIR}"

export RAILS_ENV=${RAILS_ENV:-production}
export LOGGER_STDOUT=only
export LOGGER_LEVEL=INFO
export JRUBY_OPTS="-Xcompile.invokedynamic=false -J-XX:+UseConcMarkSweepGC -J-XX:+CMSPermGenSweepingEnabled -J-XX:+CMSClassUnloadingEnabled -J-Xmx1024m"

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}
echo "$(date): About to run the new campus user sync script..." | ${LOGIT}

bundle exec rake canvas:new_user_sync |& ${LOGIT}
