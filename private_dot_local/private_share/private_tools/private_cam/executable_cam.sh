#!/usr/bin/env bash
set -euo pipefail

if ! command -v adb >/dev/null 2>&1 || ! command -v scrcpy >/dev/null 2>&1; then
  echo "adb and scrcpy are required." >&2
  exit 1
fi

VCAM_IP=${VCAM_IP-}
VCAM_DEVICE=${VCAM_DEVICE-}
VCAM_CONNECT_PORT=${VCAM_CONNECT_PORT-5555}
VCAM_PAIR_PORT=${VCAM_PAIR_PORT-37099}

[[ -z "${VCAM_IP}" ]] && read -rp "ADB IP [e.g. 192.168.1.42]: " VCAM_IP
[[ -z "${VCAM_DEVICE}" ]] && read -rp "V4L2 device [video2]: " VCAM_DEVICE
read -rp "ADB connection port [${VCAM_CONNECT_PORT}]: " _p || true
[[ -n "${_p-}" ]] && VCAM_CONNECT_PORT=$_p

# adb connect exits 0 even when it prints "failed to connect", so match the text
connected() {
  local out
  out=$(adb connect "${VCAM_IP}:${VCAM_CONNECT_PORT}" 2>&1 || true)
  printf '%s\n' "$out" >&2
  [[ $out == *"connected to"* ]]
}

if ! connected; then
  read -rp "ADB pair port [${VCAM_PAIR_PORT}]: " _pp || true
  [[ -n "${_pp-}" ]] && VCAM_PAIR_PORT=$_pp
  read -rsp "Pairing code: " _code
  echo
  # on stdin, not argv, where every user on the box could read it from /proc
  printf '%s\n' "$_code" | adb pair "${VCAM_IP}:${VCAM_PAIR_PORT}"
  connected || {
    echo "cam: still not connected to ${VCAM_IP}:${VCAM_CONNECT_PORT}" >&2
    exit 1
  }
fi

vcam_path=$VCAM_DEVICE
[[ $vcam_path != /dev/* ]] && vcam_path="/dev/$vcam_path"
[[ -e "$vcam_path" ]] || {
  echo "v4l2 device not found: $vcam_path" >&2
  exit 1
}

nowin=()
if scrcpy --help 2>&1 | grep -q -- '--no-window'; then
  nowin=(--no-window)
elif scrcpy --help 2>&1 | grep -q -- '--no-video-playback'; then
  nowin=(--no-video-playback)
fi

exec scrcpy \
  --tcpip="${VCAM_IP}:${VCAM_CONNECT_PORT}" \
  --v4l2-sink="$vcam_path" \
  ${nowin[@]+"${nowin[@]}"}
