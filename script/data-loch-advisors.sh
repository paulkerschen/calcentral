#!/bin/bash
# Script to upload instructor-advisor mapping, student-advisor mapping, and advisor note permissions data to Data Loch S3.

# Make sure the normal shell environment is in place, since it may not be
# when running as a cron job.
source "$HOME/.bash_profile"

cd $( dirname "${BASH_SOURCE[0]}" )/..

LOG=`date +"$PWD/log/data_loch_advisors_%Y-%m-%d.log"`
LOGIT="tee -a $LOG"

# Enable rvm and use the correct Ruby version and gem set.
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
source .rvmrc

export RAILS_ENV=${RAILS_ENV:-production}
export LOGGER_STDOUT=only
export LOGGER_LEVEL=INFO
export JRUBY_OPTS="--dev -J-Xmx1024m"

echo | $LOGIT
echo "------------------------------------------" | $LOGIT
echo "`date`: About to run the Data Loch Advisors script..." | $LOGIT

bundle exec rake data_loch:advisors |& $LOGIT
