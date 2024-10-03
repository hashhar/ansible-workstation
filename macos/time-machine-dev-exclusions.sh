#!/bin/bash

# Inspired by https://github.com/stevegrunwell/asimov/blob/develop/asimov

set -euo pipefail

readonly SOURCE_CODE_ROOT="$HOME/code"

# A list of "directory"/"sentinel" pairs.
#
# Directories will only be excluded if the dependency ("sentinel") file exists.
#
# For example, 'node_modules package.json' means "exclude node_modules/ from the
# Time Machine backups if there is a package.json file next to it."
readonly VENDOR_DIR_SENTINELS=(
    '.build Package.swift'             # Swift

    '.gradle build.gradle.kts'         # Gradle Kotlin Script
    '.gradle build.gradle'             # Gradle
    'build build.gradle.kts'           # Gradle Kotlin Script
    'build build.gradle'               # Gradle

    'target build.sbt'                 # Sbt (Scala)
    'target plugins.sbt'               # Sbt plugins (Scala)
    'target pom.xml'                   # Maven

    '.dart_tool pubspec.yaml'          # Flutter (Dart)
    '.packages pubspec.yaml'           # Pub (Dart)
    'build pubspec.yaml'               # Flutter (Dart)

    '.stack-work stack.yaml'           # Stack (Haskell)

    '.nox noxfile.py'                  # Nox (Python)
    '.tox tox.ini'                     # Tox (Python)
    '.venv pyproject.toml'             # virtualenv (Python)
    '.venv requirements.txt'           # virtualenv (Python)
    'build setup.py'                   # PyPI Publishing (Python)
    'dist setup.py'                    # PyPI Publishing (Python)
    'venv pyproject.toml'              # virtualenv (Python)
    'venv requirements.txt'            # virtualenv (Python)

    '.vagrant Vagrantfile'             # Vagrant

    'Carthage Cartfile'                # Carthage

    'Pods Podfile'                     # CocoaPods

    '.parcel-cache package.json'       # Parcel v2 cache (JavaScript)
    'bower_components bower.json'      # Bower (JavaScript)
    'node_modules package.json'        # npm, Yarn (NodeJS)

    'target Cargo.toml'                # Cargo (Rust)

    'vendor composer.json'             # Composer (PHP)

    'vendor Gemfile'                   # Bundler (Ruby)

    'vendor go.mod'                    # Go Modules (Golang)

    '.build mix.exs'                   # Mix build files (Elixir)
    'deps mix.exs'                     # Mix dependencies (Elixir)

    '.terraform.d .terraformrc'        # Terraform plugin cache
    '.terragrunt-cache terragrunt.hcl' # Terragrunt
    'cdk.out cdk.json'                 # AWS CDK
)

# Exclude the given paths from Time Machine backups.
# Reads the NUL-separated list of paths from stdin.
exclude_file() {
    local path
    while IFS= read -r -d '' path; do
        if tmutil isexcluded "${path}" | grep -Fq '[Excluded]'; then
            echo "- ${path#"${SOURCE_CODE_ROOT}/"} is already excluded, skipping."
            continue
        fi

        # -p means that the path is excluded even if the directory is deleted.
        # This is important for build tools which may sometimes clean the directories.
        # This may require superuser.
        sudo tmutil addexclusion -p "${path}"

        sizeondisk=$(du -hs "${path}" | cut -f1)
        echo "- ${path#"${SOURCE_CODE_ROOT}/"} has been excluded from Time Machine backups (${sizeondisk})."
    done
}

# Removes all exclusions under the $SOURCE_CODE_ROOT, useful to trim the list of exclusions periodically
clean_excludes() {
    local filtered_excludes
    filtered_excludes="$(defaults read /Library/Preferences/com.apple.TimeMachine SkipPaths \
        | grep -Fv '    "'"$SOURCE_CODE_ROOT"'')"
    echo "$filtered_excludes"
    sudo defaults write /Library/Preferences/com.apple.TimeMachine SkipPaths "$filtered_excludes"
}

# Iterate over the directory/sentinel pairs to construct the `find` expression.
declare -a find_parameters_vendor=()
for i in "${VENDOR_DIR_SENTINELS[@]}"; do
    read -ra parts <<< "${i}"

    # Add this folder to the `find` list, allowing a single `find` command to find all
    _exclude_name="${parts[0]}"
    _sibling_sentinel_name="${parts[1]}"

    # Given a directory path, determine if the corresponding file (relative
    # to that directory) is available.
    #
    # For example, when looking at a /vendor directory, we may choose to
    # ensure a composer.json file is available.
    find_parameters_vendor+=( -or \( \
        -type d \
        -name "${_exclude_name}" \
        -execdir test -e "${_sibling_sentinel_name}" \; \
        -prune \
        -print0 \
    \) )
done

printf '\n\033[0;36mFinding dependency directories with corresponding definition files…\033[0m\n'
printf '\033[0;36mAll paths are relative to %s\033[0m\n' "${SOURCE_CODE_ROOT}/"

# Export function to make it available for find -exec
export -f exclude_file
find "${SOURCE_CODE_ROOT}" \( -false "${find_parameters_vendor[@]}" \) \
    | exclude_file
