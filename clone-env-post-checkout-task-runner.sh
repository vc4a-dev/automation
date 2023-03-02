#!/bin/bash

echo 'Executing deployment/git hook task runner (via git hooks)'

changed_files="$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)"
c_branch="$(git rev-parse --abbrev-ref HEAD)"
c_time="$(date)"
c_repo="$(basename -s .git `git config --get remote.origin.url`)"

[[ "$c_repo" == "vc4a-plugins" ]] && echo "- Skipping production assets build." && exit 0;
[[ "$c_repo" == "vc4a-consulting" ]] && echo "- Skipping production assets build." && exit 0;
[[ -z "$changed_files" ]] && echo "- No changed scss/less/js/vue files found. Skipping production assets build." && exit 0;

echo "Execution started at $c_time on $c_branch at $(pwd) " >> hook_log
echo Current branch:: $c_branch
echo Current repo:: $c_repo
echo Changed Files:: $changed_files
echo $changed_files >> hook_log

# Support mu-plugins composer install and exit.
if [ "$c_repo" == "mu-plugins" ]; then
    task_runner_execution=$(echo $changed_files | grep -q 'composer.lock' && echo exists)
    if [ "$task_runner_execution" ]; then
        echo '- Running composer install...'
        composer install --no-dev || ( echo composer install --no-dev execution is FAILED && exit 1 ) || exit 1
        echo '- Composer install was successfully executed.'
        echo 'Composer install was successfully executed.' >> hook_log
    fi

    exit 0
fi

rebuildCommitChildTheme() {
    # $1 = theme folder name, $2 = repository
    echo ":: Executing build & commit changes on $2."
    
    # Maybe change folder?
    current_path="$(pwd)"
    in_path=$(echo $current_path | grep -q "$1" && echo exists)

    if [ "$in_path" ]; then
        echo "- No need to change path, already in $1 folder."
    else
        cd ../$1 || return
        echo "- Changed folder to: $(pwd)"
    fi

    commit_results='no'

    # Detect style/js updates - run gulp to build.
    if [ -e gulpfile.js ] || [ -e Gulpfile.js ]; then
        task_runner_execution=$(echo $changed_files | grep -q 'Gulpfile.js\|resources/less\|resources/js\|resources/scss\|scss\|src' && echo exists)
        if [ "$task_runner_execution" ]; then
            echo "- Clean up GULP artefacts of possible previous builds on $2..."
            rm -R resources/dist/ && git checkout -- resources/dist/
            rm -R resources/global/ && git checkout -- resources/global/
            rm -R resources/dist/ && git checkout -- resources/dist/

            echo '- Running gulp...'
            gulp build || echo gulp build execution is FAILED
            git add resources/dist/
            git add resources/global/
            git add resources/dist/
            commit_results='yes'
            echo "- Gulp build execution on $2 is successful."
            echo "- Gulp build execution on $2 is successful." >> hook_log
        fi
    fi

    # Detect Vue/Yarn build changes for themes that contain a vue config file.
    if [ -e vue.config.js ]; then
        task_runner_execution=$(echo $changed_files | grep -q 'package.json\|yarn.lock\|vue.config.js\|src' && echo exists)
        if [ "$task_runner_execution" ]; then
            echo "- YARN build changes detected for $2."

            echo '- Checking yarn version'
            yarn --version || ( echo 'Yarn command failed. Installing yarn...' && npm install -g yarn && yarn --version || echo "yarn installation is not successful. please check sources" && exit 1 ) || exit 1

            echo '- Make sure yarn dependencies are up-to-date.'
            yarn install

            echo '- Make sure @vue/cli exists.'
            yarn add @vue/cli

            echo '- Cleaning up artefacts of possible previous yarn builds...'
            echo rm -R dist/
            rm -R dist/

            echo "- Creating new build for $2..."
            if [ "$c_branch" == 'production' ]; then
                yarn build --mode production || ( echo yarn build --mode production execution is FAILED && return ) || return
            else
                yarn build --mode staging || ( echo yarn build --mode staging execution is FAILED && return ) || return
            fi

            git add dist/
            commit_results='yes'
            echo "- Build execution on $2 is successful."
            echo "- Build execution on $2 is successful." >> hook_log
        fi
    fi

    if [ "$commit_results" == "yes" ]; then
        echo "- Committing $2 build results to GIT..."
        git commit -m ":construction_worker: new auto-build created" && git push origin "$c_branch"
    fi

    echo ":: Done checking build & commit updates for $2."
    if [ "$commit_results" == "no" ]; then
        echo "- No changes were committed."
    fi
}

# Make sure when styles is updated, all styles in depending repositories are also updated.
if [ "$c_repo" == "vc4a-styles" ] && ([ "$c_branch" == "staging" ] || [ "$c_branch" == "production" ]); then
    task_runner_execution=$(echo $changed_files | grep -q 'scss' && echo exists)
    if [ "$task_runner_execution" ]; then
        rm -R dist/ && git checkout "$c_branch" -- dist/
        echo '- Rebuilding styles..'
        gulp
        git add dist/
        echo "- Committing build results to GIT..."
        git commit -m ":construction_worker: new auto-build created" && git push origin "$c_branch"

        # Also rebuild all depending (child-) repositories.
        rebuildCommitChildTheme vc4africa vc4a-theme
        rebuildCommitChildTheme academy vc4a-academy
        rebuildCommitChildTheme community vc4a-community
        rebuildCommitChildTheme mentors vc4a-mentors
        rebuildCommitChildTheme dashboard vc4a-dashboard
    fi
fi

# Do we need to create a production or staging build?
if ([ "$c_branch" == "production" ] || [ "$c_branch" == "staging" ]) && [ "$c_repo" != "vc4a-styles" ]; then
    echo 'Checking yarn version'
    yarn --version || ( echo '- Yarn command failed. Installing yarn...' && npm install -g yarn && yarn --version || echo "- Yarn installation is not successful. please check sources" && exit 1 ) || exit 1

    # Rebuild with current folder and repo.
    rebuildCommitChildTheme "${PWD##*/}" $c_repo

    success_msg='Production build task runner execution is finished.'
    echo "- $success_msg"
    echo $success_msg >> hook_log
fi

echo "Execution is completed" >> hook_log
