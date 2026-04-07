#!/usr/bin/env bash
# Shows which Homebrew packages have drifted from what ansible expects.
# Nothing is changed — safe to run anytime.
#
# Reports three categories per package type (taps, formulae, casks):
#   - Installed but not in ansible config (candidates to add or uninstall)
#   - In ansible config but not installed (missing packages)
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="default.config.yml"

# --- helpers ---

# Extract a YAML list from default.config.yml using yq.
extract_yaml_list() {
    local var_name="$1"
    yq ".${var_name}[]" "$CONFIG"
}

# Extract package names from a Brewfile dump, filtered by type prefix.
extract_brewfile() {
    local prefix="$1"
    grep "^${prefix} " "$2" \
        | sed "s/^${prefix} *//; s/^\"//; s/\"$//" \
        || true
}

# Normalize cask names: strip leading tap prefix (e.g. localsend/localsend/localsend -> localsend)
# Homebrew cask names in brew bundle dump sometimes include the tap.
normalize_cask() {
    sed 's|.*/||'
}

# Print items in list A but not in list B.
# Both inputs should be newline-separated, one item per line.
diff_lists() {
    local list_a="$1" list_b="$2"
    comm -23 <(echo "$list_a" | sort -f) <(echo "$list_b" | sort -f)
}

section() {
    local label="$1"
    shift
    local items="$*"
    if [[ -n "$items" ]]; then
        echo "  $label"
        echo "$items" | sed 's/^/    /'
        echo
    fi
}

# --- main ---

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

echo "Dumping current Homebrew state..."
brew bundle dump --file="$tmpfile" --force 2>/dev/null

# --- taps ---
installed_taps=$(extract_brewfile "tap" "$tmpfile")
configured_taps=$(extract_yaml_list "homebrew_taps")
# homebrew/bundle and homebrew/core are implicit, filter them out
installed_taps=$(echo "$installed_taps" | grep -v '^homebrew/' || true)

extra_taps=$(diff_lists "$installed_taps" "$configured_taps")
missing_taps=$(diff_lists "$configured_taps" "$installed_taps")

# --- formulae ---
installed_formulae=$(extract_brewfile "brew" "$tmpfile")
configured_formulae=$(extract_yaml_list "homebrew_installed_packages")

extra_formulae=$(diff_lists "$installed_formulae" "$configured_formulae")
missing_formulae=$(diff_lists "$configured_formulae" "$installed_formulae")

# --- casks ---
installed_casks=$(extract_brewfile "cask" "$tmpfile" | normalize_cask)
configured_casks=$(extract_yaml_list "homebrew_cask_installed_apps")

extra_casks=$(diff_lists "$installed_casks" "$configured_casks")
missing_casks=$(diff_lists "$configured_casks" "$installed_casks")

# --- report ---
echo
has_drift=false

for type in taps formulae casks; do
    extra_var="extra_${type}"
    missing_var="missing_${type}"
    extra="${!extra_var}"
    missing="${!missing_var}"
    if [[ -n "$extra" || -n "$missing" ]]; then
        has_drift=true
        echo "=== ${type^^} ==="
        section "Installed but not in config (add to config or uninstall):" "$extra"
        section "In config but not installed (run playbook or remove from config):" "$missing"
    fi
done

if ! $has_drift; then
    echo "No drift detected. Installed packages match ansible config."
fi
