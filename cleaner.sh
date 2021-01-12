#!/bin/sh
# Check js syntax for changed files with latest commits only.

# always good to know where are we and who are we!
echo "Who am I ?"
whoami
echo "Where am I ?"
pwd

DEFAULT_JENKINS_DIR="/var/lib/jenkins"
DEFAULT_JENKINS_DIR_COUNT=${#DEFAULT_JENKINS_DIR}
WORKSPACE_DIR=$(pwd)
WORKSPACE_DIR_COUNT=${#WORKSPACE_DIR}

# Make sure we are not executing rm -rf /
if [ "$WORKSPACE_DIR_COUNT" -gt "$DEFAULT_JENKINS_DIR_COUNT" ]; then
echo "Executing folder removal and re-creation."
sudo rm -rf $WORKSPACE_DIR/*
sudo rm -rf $WORKSPACE_DIR/.*
echo "Removed folder: ${WORKSPACE_DIR}"
sudo chown -R jenkins:jenkins $WORKSPACE_DIR
echo "Ownership set as jenkins:jenkins : ${WORKSPACE_DIR}"
exit 0;
fi

echo "Folders can not be removed"
exit 1;
