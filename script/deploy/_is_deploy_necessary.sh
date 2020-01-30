#!/bin/bash

######################################################
#
# If the knob-id in 'junction-deploy.properties' does
# not match the knob-id running on the server then
# this script returns true.
#
######################################################

# Abort immediately if a command fails
set -e

deployment_summary_file="${HOME}/.calcentral_config/.junction-deployment-summary"

knob_file_id=$(./script/deploy/_get-knob-file-id.sh)

if grep -q "${knob_file_id}" "${deployment_summary_file}"; then
  echo false
else
  echo true
fi

exit 0
