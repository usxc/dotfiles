#!/usr/bin/env bash
set -euo pipefail

legacy_config="${1:?Expected the legacy Git config path}"
managed_config="${2:?Expected the managed Git config path}"

[[ -f "$legacy_config" ]] || exit 0
# A user may already link ~/.gitconfig to the managed configuration.
[[ "$legacy_config" -ef "$managed_config" ]] && exit 0

# Only direct defaults conflict with the defaults managed by this project.
# Keep included files, conditional identities, authentication and signing intact.
managed_keys=()
for key in user.name user.email init.defaultBranch; do
  if git config --file "$legacy_config" --no-includes --get-all "$key" >/dev/null; then
    managed_keys+=("$key")
  else
    result=$?
    [[ "$result" -eq 1 ]] || exit "$result"
  fi
done
[[ "${#managed_keys[@]}" -gt 0 ]] || exit 0

if [[ -n "${DRY_RUN+x}" ]]; then
  printf 'Would migrate conflicting Git defaults in %s\n' "$legacy_config"
  exit 0
fi

# Resolve symlinks so editing preserves both the link and Git's normal lock.
config_target="$(realpath "$legacy_config")"
lock_path="${config_target}.lock"
umask 077
if ! (set -o noclobber; : > "$lock_path") 2>/dev/null; then
  printf 'Error: could not lock Git config: %s\n' "$config_target" >&2
  exit 1
fi
trap 'rm -f "$lock_path" "$lock_path.lock"' EXIT

# Work on the locked copy; publish all changes together only after validation.
cp -p "$config_target" "$lock_path"
backup="$(mktemp "${legacy_config}.before-dotfiles.XXXXXX")"
if ! cp "$lock_path" "$backup"; then
  rm -f "$backup"
  exit 1
fi

for key in "${managed_keys[@]}"; do
  git config --file "$lock_path" --no-includes --unset-all "$key"
done

if [[ "$(realpath "$legacy_config")" != "$config_target" ]] \
  || ! cmp -s "$config_target" "$backup"; then
  printf 'Error: Git config changed during migration; retry activation: %s\n' "$legacy_config" >&2
  exit 1
fi

mv -f "$lock_path" "$config_target"
trap - EXIT
printf 'Migrated Git defaults; original config saved to %s\n' "$backup"
