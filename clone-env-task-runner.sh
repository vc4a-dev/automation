#!/bin/bash

echo 'Executing clone environment production build task runner (via git hooks)'

if [ "$3" == 0 ] || [ "$3" == 1 ]; then
    echo 'Checkout operation.'
    if [ $1 == $2 ]; then
        echo 'Already on same branch skipping checkout hooks.'
        exit 0
    fi
    changed_files="$(git diff-tree -r --name-only --no-commit-id $1 $2)"
else
    changed_files="$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)"
fi

c_branch="$(git rev-parse --abbrev-ref HEAD)"
c_time="$(date)"
echo "Execution started at $c_time on $c_branch at $(pwd) " >> hook_log

if [ "$c_branch" == "production" ]; then

    echo current_branch : $c_branch
    echo 'Checking current user'
    whoami
    echo 'Checking npm'
    which npm
    echo 'Checking yarn version'
    yarn --version || ( echo 'Yarn command failed. Installing yarn...' && npm install -g yarn && yarn --version || echo "yarn installation is not successful. please check sources" && exit 1 ) || exit 1
    build_state=nope
    if something-horrible; then
      build_state=failed
    fi

    c_repo="$(basename -s .git `git config --get remote.origin.url`)"
    echo Current repo: $c_repo
    echo "Current repo $c_repo " >> hook_log

    [[ -z "$changed_files" ]] && echo "No changed scss/less/js files found. Skipping production build." && exit 0;
    echo Changed Files : $changed_files
    echo $changed_files >> hook_log

    # Detect style updates - run gulp?
    task_runner_execution=$(echo $changed_files | grep -q 'resources/scss\|resources/less\|resources/js\|Gulpfile.js' && echo exists)
    if [[ "$task_runner_execution" ]] ; then
        echo 'Clean up artefacts of possible previous builds...'
        rm -R resources/dist/
        rm -R resources/global/

        echo 'SCSS/LESS/JS changes detected. Running "gulp build"'
        gulp build || ( echo gulp build execution is FAILED && exit 1 ) || exit 1
        build_state=done
        git add resources/dist/
        git add resources/global/
        echo " Gulp build execution is successful."
        echo " Gulp build execution is successful." >> hook_log
    fi

    task_runner_execution=$(echo $changed_files | grep -q 'vue.config.js\|src' && echo exists)
    if [[ "$task_runner_execution" ]] ; then
        echo 'Clean up artefacts of possible previous builds...'
        rm -R dist/
        git checkout "$c_branch" -- dist/

        echo 'Production build changes detected. Running "yarn build --mode production"'
        yarn build --mode production || ( echo yarn build --mode production execution is FAILED && exit 1 ) || exit 1
        build_state=done
        git add dist/
        echo " Production build execution is successful."
        echo " Production build execution is successful." >> hook_log
    fi

    if [[ "$build_state" == "done" ]]; then
        echo 'Committing new build to git'
        git commit -m ":construction_worker: new production build created" && git push origin "$c_branch"
    fi

    success_msg='Production build task runner execution is finished.'
    echo $success_msg
    echo $success_msg >> hook_log
else
    echo "Skipping production build task runner hooks."
fi

echo "Execution is completed" >> hook_log
