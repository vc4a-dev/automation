#!/bin/sh
# Automatically merge the last commit through the following branches:
# production -> master -> staging -> development

# always good to know where are we and who are we!
whoami
pwd

#set permissions and ownerships
sudo chown -R jenkins:jenkins ../
sudo chmod -R 777 ../

#skip if last commit already an auto merge commit
git log -1 | grep 'auto merge with ' && echo "Last commit is already an auto-merge commit. Skipping..." && exit 0
#check skip ci directive.
git log -1 | grep '\[skip ci\]' && echo "Last commit has skip CI directive. Skipping..." && exit 0
git log -1 | grep '\[ci skip\]' && echo "Last commit has skip CI directive. Skipping..." && exit 0
#check skip merge directive
git log -1 | grep '\[skip merge\]' && echo "Last commit has skip merge directive. Skipping..." && exit 0
git log -1 | grep '\[merge skip\]' && echo "Last commit has skip merge directive. Skipping..." && exit 0

CURRENT_BRANCH=$1
LAST_COMMIT=$(git rev-list -1 HEAD)
REPOSITORY_URL=$2
# stripping https://github.com/
REPOSITORY_NAME=${REPOSITORY_URL:19}

case $CURRENT_BRANCH in
development)
  echo "development branch does not have any sub-branches. Skipping operation."
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
  echo "Auto-merging with master."
  ( git checkout -f master && git pull origin master && git merge --no-ff -m "auto merge with $CURRENT_BRANCH" $CURRENT_BRANCH && git push origin master ) || ( echo "auto merge failed." && exit 1 )
  echo "Auto-merging with staging."
  ( git checkout -f staging && git pull origin staging && git merge --no-ff -m "auto merge with $CURRENT_BRANCH" $CURRENT_BRANCH && git push origin staging ) || ( echo "auto merge failed." && exit 1 )
  exitcode=$?
  echo "Sub-merges are done!."
  ;;
master)
  echo "Auto-merging with staging."
  ( git checkout -f staging && git pull origin staging && git merge --no-ff -m "auto merge with $CURRENT_BRANCH" $CURRENT_BRANCH && git push origin staging ) || ( echo "auto merge failed." && exit 1 )
  exitcode=$?
  echo "Sub-merges are done!."
  ;;
esac


if [ $exitcode == 0 ];
    then
    echo "Branch synching is done."
    git checkout -f .
    git checkout -f $CURRENT_BRANCH || ( echo "checkout to $CURRENT_BRANCH branch failed." && exit 1 )
    exit 0;
fi

git checkout -f .
git checkout -f $CURRENT_BRANCH
echo "Branch synching is failed.";
exit 1;
