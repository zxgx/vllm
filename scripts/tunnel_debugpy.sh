#!/usr/bin/env bash

set -euo pipefail

# Build an SSH tunnel to a running PBS interactive job node by parsing qstat -f.
#
# Usage:
#   scripts/tunnel_debugpy.sh [job_id] [local_port] [remote_port]
#
# Examples:
#   scripts/tunnel_debugpy.sh
#   scripts/tunnel_debugpy.sh 470819.hopper-m-02
#   scripts/tunnel_debugpy.sh 470819.hopper-m-02 5678 5678

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage:
  scripts/tunnel_debugpy.sh [job_id] [local_port] [remote_port]

Examples:
  scripts/tunnel_debugpy.sh
  scripts/tunnel_debugpy.sh 470819.hopper-m-02
  scripts/tunnel_debugpy.sh 470819.hopper-m-02 5678 5678
EOF
  exit 0
fi

JOB_ID="${1:-}"
LOCAL_PORT="${2:-5678}"
REMOTE_PORT="${3:-5678}"

if ! command -v qstat >/dev/null 2>&1; then
  echo "Error: qstat not found in PATH." >&2
  exit 1
fi

if [[ -z "${JOB_ID}" ]]; then
  # Parse from qstat -f to avoid brittle fixed-column parsing from qstat table.
  JOB_ID="$(qstat -f | awk '/^Job Id:/ {id=$3} /job_state = R/ {print id; exit}')"
fi

if [[ -z "${JOB_ID}" ]]; then
  echo "Error: no running job found. Pass a job id explicitly." >&2
  exit 1
fi

QSTAT_OUT="$(qstat -f "${JOB_ID}")"

# Prefer dedicated top-level fields; avoid parsing wrapped Variable_List entries.
LOGIN_HOST="$(
  printf '%s\n' "${QSTAT_OUT}" \
    | awk -F'= ' '/^[[:space:]]*Submit_Host = / {print $2; exit}' \
    | xargs
)"
COMPUTE_HOST_RAW="$(
  printf '%s\n' "${QSTAT_OUT}" \
    | awk -F'= ' '/^[[:space:]]*exec_host = / {print $2; exit}' \
    | xargs
)"
USER_NAME="$(
  printf '%s\n' "${QSTAT_OUT}" \
    | awk -F'= ' '/^[[:space:]]*Job_Owner = / {print $2; exit}' \
    | awk -F'@' '{print $1}' \
    | xargs
)"

if [[ -z "${LOGIN_HOST}" || -z "${COMPUTE_HOST_RAW}" || -z "${USER_NAME}" ]]; then
  echo "Error: failed to parse qstat output for ${JOB_ID}." >&2
  exit 1
fi

# exec_host format is typically like: hopper-21/2*24
COMPUTE_HOST="${COMPUTE_HOST_RAW%%/*}"

echo "Job ID:        ${JOB_ID}"
echo "User:          ${USER_NAME}"
echo "Login host:    ${LOGIN_HOST}"
echo "Compute host:  ${COMPUTE_HOST}"
echo "Tunnel:        127.0.0.1:${LOCAL_PORT} -> ${COMPUTE_HOST}:127.0.0.1:${REMOTE_PORT}"
echo
echo "Starting tunnel (Ctrl+C to stop)..."

exec ssh -N \
  -J "${USER_NAME}@${LOGIN_HOST}" \
  "${USER_NAME}@${COMPUTE_HOST}" \
  -L "${LOCAL_PORT}:127.0.0.1:${REMOTE_PORT}"
