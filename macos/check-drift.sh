#!/usr/bin/env bash
# Shows which macOS defaults have drifted from what ansible expects.
# Nothing is changed — safe to run anytime.
# Run after a macOS update or after making manual changes in System Settings
# to check what still needs to be re-applied.
set -euo pipefail
cd "$(dirname "$0")"
source venv/bin/activate
ansible-playbook -i inventory --check --diff main.yml --tags defaults
