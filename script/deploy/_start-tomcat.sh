#!/bin/bash

######################################################
#
# Start Tomcat
#
######################################################

# Abort immediately if a command fails
set -e

DOC_ROOT="/var/www/html/junction"
MAX_ASSET_AGE_IN_DAYS=${MAX_ASSET_AGE_IN_DAYS:="45"}

# Boilerplate logging scheme

LOG=$(date +"${PWD}/log/update-build_%Y-%m-%d.log")
LOGIT="tee -a ${LOG}"

function log_error {
  echo | ${LOGIT}
  echo "$(date): [ERROR] ${1}" | ${LOGIT}
  echo | ${LOGIT}
}

function log_info {
  echo "$(date): [INFO] ${1}" | ${LOGIT}
}

echo | ${LOGIT}

echo | ${LOGIT}
echo "------------------------------------------" | ${LOGIT}

cd ${TOMCAT_DEPLOY} || exit 1

# Start Tomcat, deploying WAR contents in the process
sudo systemctl start tomcat9@junction | ${LOGIT}

# Wait 20 seconds before deploy
sleep 20

if [ ! -d "ROOT/WEB-INF/versions" ]; then
  echo "$(date): ERROR: Missing or malformed junction.war file!" | ${LOGIT}
  exit 1
fi
echo "Last commit in junction.war deployed:" | ${LOGIT}
cat ${TOMCAT_DEPLOY}/ROOT/WEB-INF/versions/git.txt | ${LOGIT}

log_info "Copying assets into ${DOC_ROOT}"
cp -Rvf ${TOMCAT_DEPLOY}/ROOT/WEB-INF/public/assets ${DOC_ROOT} | ${LOGIT}

log_info "Deleting old assets from ${DOC_ROOT}/assets"
find ${DOC_ROOT}/assets -type f -mtime +${MAX_ASSET_AGE_IN_DAYS} -delete | ${LOGIT}

log_info "Copying bCourses static files into ${DOC_ROOT}"
cp -Rvf ${TOMCAT_DEPLOY}/ROOT/WEB-INF/public/canvas ${DOC_ROOT} | ${LOGIT}

log_info "Copying OAuth static files into ${DOC_ROOT}"
cp -Rvf ${TOMCAT_DEPLOY}/ROOT/WEB-INF/public/oauth ${DOC_ROOT} | ${LOGIT}

# Fix file permissions for Tomcat deploys
cd ${DOC_ROOT}

chmod -R o+r *

chmod -R g+w *

# Give execute to others for directories only
find ${DOC_ROOT} -type d -execdir chmod o+x {} \;

log_info "Congratulations, startup complete."

echo | ${LOGIT}

exit 0
