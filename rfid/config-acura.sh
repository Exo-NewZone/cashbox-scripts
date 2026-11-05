#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  printf 'Please run as root\n' >&2
  exit 1
fi

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  printf 'Usage: %s <serial-device>\n' "$0" >&2
  exit 2
fi

SERIAL_DEVICE=$1
LINK_PATH=/dev/exo/rfid-serial

if [[ "$SERIAL_DEVICE" != /* || ! -c "$SERIAL_DEVICE" ]]; then
  printf 'Serial device must be an absolute path to a character device: %s\n' "$SERIAL_DEVICE" >&2
  exit 2
fi

apt-get install -y picocom
mkdir -p /dev/exo

if [[ -e "$LINK_PATH" && ! -L "$LINK_PATH" ]]; then
  printf 'Refusing to replace non-symlink path: %s\n' "$LINK_PATH" >&2
  exit 1
fi

ln -sfn -- "$SERIAL_DEVICE" "$LINK_PATH"

picocom -q -b 115200 -x 1000 -t $'readmode serial\r' "$LINK_PATH"

echo "Configuration complete. Serial device linked at $LINK_PATH"
