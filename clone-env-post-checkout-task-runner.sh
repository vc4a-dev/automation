#!/bin/bash

echo 'Executing deployment/git hook task runner (via git hooks)'

changed_files="$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)"
c_branch="$(git rev-parse --abbrev-ref HEAD)"
c_time="$(date)"
c_repo="$(basename -s .git `git config --get remote.origin.url`)"

[[ "$c_repo" == "vc4a-plugins" ]] && echo "Skipping production assets build." && exit 0;
[[ "$c_repo" == "vc4a-consulting" ]] && echo "Skipping production assets build." && exit 0;
[[ -z "$changed_files" ]] && echo "No changed scss/less/js/vue files found. Skipping production assets build." && exit 0;

echo "Execution started at $c_time on $c_branch at $(pwd) " >> hook_log

# Support mu-plugins composer install and exit.
if [ "$c_repo" == "mu-plugins" ]; then
    task_runner_execution=$(echo $changed_files | grep -q 'composer.lock' && echo exists)
    if [[ "$task_runner_execution" ]]; then
        echo 'Running composer install...'
        composer install --no-dev || ( echo composer install --no-dev execution is FAILED && exit 1 ) || exit 1
        echo 'Composer install was successfully executed.'
        echo 'Composer install was successfully executed.' >> hook_log
    fi

    exit 0
fi

# Do we need to create a production build?
if [ "$c_branch" == "production" ]; then
    echo current_branch:: $c_branch
    echo Current repo:: $c_repo
    echo 'Checking yarn version'
    yarn --version || ( echo 'Yarn command failed. Installing yarn...' && npm install -g yarn && yarn --version || echo "yarn installation is not successful. please check sources" && exit 1 ) || exit 1
    build_state='no build'

    echo Changed Files : $changed_files
    echo $changed_files >> hook_log

    # Detect style/js updates - run gulp to build.
    if [ "$c_repo" != "vc4a-dashboard" ]; then
        task_runner_execution=$(echo $changed_files | grep -q 'resources/scss\|resources/less\|resources/js\|Gulpfile.js' && echo exists)
        if [[ "$task_runner_execution" ]] ; then
            echo 'GULP build changes detected.'
            echo 'Clean up artefacts of possible previous builds...'
            rm -R resources/dist/
            rm -R resources/global/

            echo 'SCSS/LESS/JS changes detected. Running "gulp build"...'
            gulp build || ( echo gulp build execution is FAILED && exit 1 ) || exit 1
            build_state='executed'
            git add resources/dist/
            git add resources/global/
            echo "Gulp build execution is successful."
            echo "Gulp build execution is successful." >> hook_log
        fi
    fi

    if [ "$c_repo" == "vc4a-mentors" ] || [ "$c_repo" == "vc4a-dashboard" ] || [ "$c_repo" == "vc4a-theme" ]; then
        task_runner_execution=$(echo $changed_files | grep -q 'package.json\|yarn.lock\|vue.config.js\|src' && echo exists)
        if [[ "$task_runner_execution" ]]; then
            echo 'YARN build changes detected.'
            echo 'Cleaning up artefacts of possible previous yarn builds...'
            echo rm -R dist/
            rm -R dist/
            echo git reset -- dist/
            git reset -- dist/

            echo 'Creating new build...'
            yarn build --mode production || ( echo yarn build --mode production execution is FAILED && exit 1 ) || exit 1
            build_state='executed'
            git add dist/
            echo "Production build execution is successful."
            echo "Production build execution is successful." >> hook_log
        fi
    fi

    if [[ "$build_state" == "executed" ]]; then
        echo 'Committing new build results to git'
        git commit -m ":construction_worker: new production build created" && git push origin "$c_branch"
    fi

    success_msg='Production build task runner execution is finished.'
    echo $success_msg
    echo $success_msg >> hook_log
else
    echo "Skipping production build task runner hooks."
fi

echo "Execution is completed" >> hook_log
