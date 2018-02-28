#!/bin/sh
# Automatically merge the last commit through the following branches:
# production -> master -> staging -> development

# always good to know where are we and who are we!
whoami
pwd

CURRENT_BRANCH=$1
LAST_COMMIT=$(git rev-list -1 HEAD)
REPOSITORY_URL=$2
# stripping https://github.com/
REPOSITORY_NAME=${REPOSITORY_URL:19}

case $CURRENT_BRANCH in
development)
  'development branch does not have any sub-branches. Skipping operation.'
  exit 0
  ;;
esac

git remote set-url origin git@github.com:${REPOSITORY_NAME}
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git checkout -f $CURRENT_BRANCH
echo "Fetching all"
git fetch --all
git pull origin $CURRENT_BRANCH
echo "Automatically merging commit $LAST_COMMIT from $CURRENT_BRANCH rippling to sub-branches"
case $CURRENT_BRANCH in
production)
  ( git checkout -f master && git pull origin master && git merge --no-ff $CURRENT_BRANCH -m "auto merge with $CURRENT_BRANCH" && git push origin master ) || ( echo "auto merge failed." && exit 1 )
  ;;
master)
  ( git checkout -f staging && git pull origin staging && git merge --no-ff $CURRENT_BRANCH -m "auto merge with $CURRENT_BRANCH" && git push origin staging ) || ( echo "auto merge failed." && exit 1 )
  ;;
staging)
  ( git checkout -f development && git pull origin development && git merge --no-ff $CURRENT_BRANCH -m "auto merge with $CURRENT_BRANCH" && git push origin development ) || ( echo "auto merge failed." && exit 1 )
  ;;
esac

git checkout $CURRENT_BRANCH || ( echo "auto merge failed." && exit 1 )
