#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_SCRIPT="$SCRIPT_DIR/SSH.sh"
REMOTE_WORKSPACE=""

usage() {
  cat <<USAGE >&2
Usage:
  $(basename "$0") <remote-command> [args...]
  $(basename "$0") <local-file> [additional-local-files...] [-- args...]

Examples:
  $(basename "$0") uname -a
  $(basename "$0") ./backup.sh -- --flag value
USAGE
}

die() {
  local message="$1"
  local exit_code="${2:-1}"
  echo "$message" >&2
  exit "$exit_code"
}

abs_path() {
  local target="$1"
  if [[ "$target" == /* ]]; then
    printf '%s\n' "$target"
    return
  fi
  local dir
  dir=$(cd "$(dirname "$target")" && pwd -P)
  local base
  base=$(basename "$target")
  printf '%s/%s\n' "$dir" "$base"
}

generate_remote_dir() {
  local token
  if command -v uuidgen >/dev/null 2>&1; then
    token=$(uuidgen | tr 'A-Z' 'a-z')
  else
    token="$(date +%s%N).$$.$RANDOM"
  fi
  printf '/tmp/runinoslo.%s\n' "$token"
}

cleanup_remote() {
  local dir="$1"
  if [[ -z "$dir" ]]; then
    return
  fi
  "$SSH_SCRIPT" sh -c 'rm -rf -- "$1"' sh "$dir" >/dev/null 2>&1 || true
}

ensure_remote_dir() {
  local dir="$1"
  if ! "$SSH_SCRIPT" sh -c 'mkdir -p -- "$1"' sh "$dir"; then
    die "Failed to create remote workspace"
  fi
}

upload_file() {
  local local_path="$1"
  local remote_path="$2"
  if ! "$SSH_SCRIPT" sh -c 'cat > "$1"' sh "$remote_path" < "$local_path"; then
    die "Failed to upload $(basename "$local_path")"
  fi
  if ! "$SSH_SCRIPT" sh -c 'chmod +x -- "$1"' sh "$remote_path" >/dev/null; then
    die "Failed to set executable bit for $(basename "$local_path")"
  fi
}

execute_remote_file() {
  local remote_dir="$1"
  local base="$2"
  shift 2
  "$SSH_SCRIPT" sh -c 'cd "$1" && "./$2" "$@"' sh "$remote_dir" "$base" "$@"
}

run_local_files() {
  local -n files_ref=$1
  local -n script_args_ref=$2

  local remote_dir
  remote_dir=$(generate_remote_dir)
  ensure_remote_dir "$remote_dir"

  REMOTE_WORKSPACE="$remote_dir"
  trap 'cleanup_remote "$REMOTE_WORKSPACE"' EXIT

  local idx
  for idx in "${!files_ref[@]}"; do
    local file="${files_ref[$idx]}"
    local abs
    abs=$(abs_path "$file")
    if [[ ! -f "$abs" ]]; then
      die "File not found: $file"
    fi

    local base
    base=$(basename "$file")
    local remote_path="$remote_dir/$base"

    upload_file "$abs" "$remote_path"

    local -a to_pass=()
    if [[ $idx -eq 0 && ${#script_args_ref[@]} -gt 0 ]]; then
      to_pass=("${script_args_ref[@]}")
    fi

    execute_remote_file "$remote_dir" "$base" "${to_pass[@]}"
    local status=$?
    if (( status != 0 )); then
      exit $status
    fi
  done

  cleanup_remote "$REMOTE_WORKSPACE"
  REMOTE_WORKSPACE=""
  trap - EXIT
}

main() {
  local -a local_files=()
  local -a script_args=()
  local -a command_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --)
        shift
        script_args=("$@")
        break
        ;;
      *)
        if (( ${#local_files[@]} )); then
          if [[ -f "$1" ]]; then
            local_files+=("$1")
            shift
            continue
          fi
          script_args=("$@")
          break
        fi
        if [[ -f "$1" ]]; then
          local_files+=("$1")
          shift
        else
          command_args=("$@")
          break
        fi
        ;;
    esac
  done

  if (( ${#local_files[@]} )); then
    run_local_files local_files script_args
  elif (( ${#command_args[@]} )); then
    "$SSH_SCRIPT" "${command_args[@]}"
  else
    usage
    exit 1
  fi
}

if [[ ! -x "$SSH_SCRIPT" ]]; then
  die "SSH script not found or not executable: $SSH_SCRIPT"
fi

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

main "$@"
