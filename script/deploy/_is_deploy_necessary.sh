#!/bin/bash

######################################################
#
# If the war-id in 'junction-deploy.properties' does
# not match the war-id running on the server then
# this script returns true.
#
######################################################

# Abort immediately if a command fails
set -e

deployment_summary_file="${HOME}/.calcentral_config/.junction-deployment-summary"

war_file_id=$(./script/deploy/_get-war-file-id.sh)

if grep -q "${war_file_id}" "${deployment_summary_file}"; then
  echo false
else
  echo true
fi

exit 0
