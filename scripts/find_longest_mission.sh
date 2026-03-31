#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

log_file="${repo_root}/space_missions.log"
destination="Mars"
status="Completed"
show_details="false"

usage() {
  cat <<'EOF'
Usage: ./scripts/find_longest_mission.sh [options]

Find the security code for the longest mission matching a destination and status.

Options:
  --log-file PATH       Mission log to analyze. Defaults to ./space_missions.log
  --destination VALUE   Destination to match. Defaults to Mars
  --status VALUE        Status to match. Defaults to Completed
  --details             Print destination, status, duration, and security code
  --help                Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-file)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --log-file" >&2
        exit 1
      fi
      log_file="$2"
      shift 2
      ;;
    --destination)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --destination" >&2
        exit 1
      fi
      destination="$2"
      shift 2
      ;;
    --status)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --status" >&2
        exit 1
      fi
      status="$2"
      shift 2
      ;;
    --details)
      show_details="true"
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$log_file" ]]; then
  echo "Log file not found: $log_file" >&2
  exit 1
fi

awk '/^[[:space:]]*#/ { next } /^[[:space:]]*$/ { next } /\|/ { print }' "$log_file" |
awk -F'|' -v destination="$destination" -v status="$status" -v show_details="$show_details" '
function trim(value) {
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
  return value
}

{
  mission_destination = trim($3)
  mission_status = trim($4)
  mission_duration = trim($6) + 0
  security_code = trim($8)

  if (mission_destination == destination && mission_status == status && mission_duration > max_duration) {
    max_duration = mission_duration
    max_code = security_code
    found = 1
  }
}

END {
  if (!found) {
    printf("No mission found for destination=\"%s\" and status=\"%s\"\n", destination, status) > "/dev/stderr"
    exit 2
  }

  if (show_details == "true") {
    printf("destination=%s status=%s duration=%d security_code=%s\n", destination, status, max_duration, max_code)
    exit 0
  }

  print max_code
}
'