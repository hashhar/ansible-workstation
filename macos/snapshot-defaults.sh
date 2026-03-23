#!/usr/bin/env bash
# Snapshots ALL macOS defaults domains to JSON files in defaults-snapshot/.
#
# Workflow:
#   1. Commit the snapshot before a macOS update
#   2. After updating, re-run this script
#   3. `git diff defaults-snapshot/` to see what changed, disappeared, or appeared
#
# Keys that disappeared: consider removing from defaults/tasks/main.yml
# Keys that reset:       re-run ansible or update expected values in the playbook
# Interesting new keys:  use `plistwatch` to discover what UI settings map to which keys:
#   plistwatch -domain com.apple.dock   # in a separate terminal while changing settings
set -euo pipefail

SNAPSHOT_DIR="$(dirname "$0")/defaults-snapshot"
mkdir -p "$SNAPSHOT_DIR"

# `defaults domains` returns a comma+space separated list of all known domains
IFS=', ' read -r -a DOMAINS <<< "$(defaults domains)"

success=0
failed=0
for domain in "${DOMAINS[@]}"; do
  # Skip domains that look like flags (e.g. --help returned by `defaults domains`)
  [[ "$domain" == -* ]] && continue
  outfile="$SNAPSHOT_DIR/${domain}.json"
  if defaults export "$domain" - 2>/dev/null | plutil -convert json -r -o "$outfile" - 2>/dev/null; then
    ((++success))
  else
    echo "WARN: could not export $domain"
    ((++failed))
  fi
done

echo ""
echo "Done: $success domains exported, $failed failed."
echo "Run 'git diff defaults-snapshot/' to see changes since last snapshot."
