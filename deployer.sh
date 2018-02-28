#!/bin/sh
# Make deployments.

# always good to know where are we and who are we!
whoami
pwd

CURRENT_BRANCH=$1
LAST_COMMIT=$(git rev-list -1 HEAD)
REPOSITORY_URL=$2
# stripping https://github.com/
REPOSITORY_NAME=${REPOSITORY_URL:19}


case $CURRENT_BRANCH in
production)
  URL="clone.staging-vc4a.com"
  ;;
master)
  URL="master.staging-vc4a.com"
  ;;
staging)
  URL="staging-vc4a.com"
  ;;
development)
  URL="dev.staging-vc4a.com"
  ;;
esac

MAIN_PATH="/var/www/html/"${URL}

case $REPOSITORY_NAME in
billz/vc4a-theme.git)
  SUB_PATH=${MAIN_PATH}"/wp-content/themes/vc4africa"
  JS_COMMANDS="npm install && gulp build"
  ;;
billz/theme-academy.git)
  SUB_PATH=${MAIN_PATH}"/wp-content/themes/academy"
  JS_COMMANDS="npm install && gulp build"
  ;;
billz/consulting.git)
  SUB_PATH=${MAIN_PATH}"/wp-content/themes/consulting"
  JS_COMMANDS="npm install && gulp build"
  ;;
billz/mu-plugins.git)
  SUB_PATH=${MAIN_PATH}"/wp-content/mu-plugins"
  JS_COMMANDS="composer update"
  ;;
billz/plugins.git)
  SUB_PATH=${MAIN_PATH}"/wp-content/plugins"
  JS_COMMANDS=""
  ;;
esac

echo $URL
echo $MAIN_PATH
echo $SUB_PATH
echo $JS_COMMANDS

SCRIPT="#!/bin/sh \n
echo 'Entering to sub path' \n
cd $SUB_PATH || exit 1 \n
echo 'Checkout to branch' \n 
sudo git checkout -f . || git checkout -f $CURRENT_BRANCH \n
echo 'Update the branch' \n
( sudo git pull || sudo git pull ) || exit 1 \n
echo 'Execute Javascript task runner commands' \n
( sudo $JS_COMMANDS || sudo $JS_COMMANDS ) || exit 1 \n
echo 'Set folder ownerships' \n
( sudo chown -R www-data:deploy $MAIN_PATH ) || exit 1 \n
"

if [ -e dynamic_deploy.sh ]; then
  rm dynamic_deploy.sh
fi

echo -e $SCRIPT >> dynamic_deploy.sh


( ssh deploy@${URL} 'bash -s' < dynamic_deploy.sh ) || ( echo 'deployment is failed' && exit 1 )
