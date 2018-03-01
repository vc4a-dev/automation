#!/bin/sh
# Make deployments.

# always good to know where are we and who are we!
whoami
pwd

REPOSITORY_URL=$1
# stripping https://github.com/
REPOSITORY_NAME=${REPOSITORY_URL:19}

case $REPOSITORY_NAME in
billz/vc4a-theme.git)
  JS_COMMANDS="sudo npm install && sudo gulp build"
  ;;
billz/theme-academy.git)
  JS_COMMANDS="sudo npm install && sudo gulp build"
  ;;
billz/vc4a-service-theme.git)
  JS_COMMANDS="pwd"
  ;;
billz/mu-plugins.git)
  JS_COMMANDS="sudo composer update"
  sed -i -e 's/\.\.\///g' composer.json
  sudo rm -rf plugins
  sudo rm -rf themes
  ;;
billz/vc4a-plugins.git)
  JS_COMMANDS="pwd"
  ;;
esac

rm -rf node_modules
echo "Executing task runner commands"
echo $JS_COMMANDS
echo $( ( $JS_COMMANDS || $JS_COMMANDS ) || ( echo "TASK RUNNER COMMANDS FAILED " && exit 1) )
# remove sed replacements
git checkout -f . || git checkout -f . || ( echo 'git checkout failed' && exit 1 )
echo "Task runner commands are succeeded."