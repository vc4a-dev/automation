#!/bin/sh
# Check js syntax for changed files with latest commits only.

# always good to know where are we and who are we!
echo "Who am I ?"
whoami
echo "Where am I ?"
pwd

WORKSPACE_DIR=$(pwd)
echo $WORKSPACE_DIR