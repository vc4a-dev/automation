#!/bin/sh
# Make deployments.

# always good to know where are we and who are we!
whoami
pwd

REPOSITORY_URL=$1
# stripping https://github.com/
REPOSITORY_NAME=${REPOSITORY_URL:19}
CURRENT_BRANCH=$2

if [ $CURRENT_BRANCH != "development" ] && [ $CURRENT_BRANCH != "staging" ] && [ $CURRENT_BRANCH != "master" ] && [ $CURRENT_BRANCH != "production" ]
then
echo "For pull reqeusts we will use default current branch master";
CURRENT_BRANCH="master"
fi

GULP_COMMANDS=""
NPM_COMMANDS=""
COMPOSER_COMMANDS=""

case $REPOSITORY_NAME in
billz/vc4a-theme.git)
  sudo rm -rf node_modules
  NPM_COMMANDS="sudo npm install"
  GULP_COMMANDS="sudo gulp build"
  ;;
billz/theme-academy.git)
  sudo rm -rf vc4africa
  sudo rm -rf node_modules
  git clone -b $CURRENT_BRANCH git@github.com:billz/vc4a-theme.git vc4africa
  #sed -i -e 's/\.\.\/\.\.\/\.\.\/vc4africa/vc4africa/g' resources/less/style.less
  for i in $(find . -iname "*.less"); do sed -i -e 's/\.\.\/\.\.\/\.\.\/\.\.\/vc4africa/vc4africa/g' $i; done
  for i in $(find . -iname "*.less"); do sed -i -e 's/\.\.\/\.\.\/\.\.\/vc4africa/vc4africa/g' $i; done
  NPM_COMMANDS="sudo npm install"
  GULP_COMMANDS="sudo gulp build"
  ;;
billz/vc4a-service-theme.git)
  echo "no commands available for vc4a-service-theme"
  ;;
billz/mu-plugins.git)
  rm -f composer.phar
  sudo wget https://getcomposer.org/download/1.6.3/composer.phar
  COMPOSER_COMMANDS="sudo hhvm -dhhvm.jit=0 -dmemory_limit=1024M  -v Eval.JitAutoTCShift=0 -v Eval.Jit=false composer.phar update -n --prefer-dist"
  sed -i -e 's/\.\.\///g' composer.json
  sudo rm -rf plugins
  sudo rm -rf themes
  ;;
billz/vc4a-plugins.git)
  echo "no commands available for vc4a-service-theme"
  ;;
esac


echo "Executing task runner commands"
if [ -n "$NPM_COMMANDS" ];
then
echo $NPM_COMMANDS;
$NPM_COMMANDS || $NPM_COMMANDS || exit 1
exitcode=$?
    if [ $exitcode != 0 ];
        then
        echo "$NPM_COMMANDS failed"
        exit $exitcode;
    fi
fi

if [ -n "$GULP_COMMANDS" ];
then
echo $GULP_COMMANDS;
$GULP_COMMANDS || $GULP_COMMANDS || exit 1
exitcode=$?
    if [ $exitcode != 0 ];
        then
        echo "$GULP_COMMANDS failed"
        exit $exitcode;
    fi
fi

if [ -n "$COMPOSER_COMMANDS" ];
then
echo $COMPOSER_COMMANDS;
$COMPOSER_COMMANDS || $COMPOSER_COMMANDS || $COMPOSER_COMMANDS || exit 1
exitcode=$?
    if [ $exitcode != 0 ];
        then
        echo "$COMPOSER_COMMANDS failed"
        exit $exitcode;
    fi
fi

# remove sed replacements
git checkout -f . || git checkout -f . || ( echo 'git checkout failed' && exit 1 )
echo "Task runner commands are succeeded."