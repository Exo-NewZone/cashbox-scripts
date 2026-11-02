#!/bin/bash
HELP="""
Usage: $0 [-f] [-h]
Options:
  -h    Show this help message
  -f    Turn off local hostnames
"""


HOSTNAME="""
10.10.100.23    sale-api.newzone.com.py
10.10.100.23    products-api.newzone.com.py
10.10.100.23    cashbox-api.newzone.com.py
10.10.100.23    cashbox-payment-methods-api.newzone.com.py
"""
HOST_FILE="/etc/hosts"

print_usage() {
  echo "$HELP"
}

print_host_file() {
  cat "$HOST_FILE"
}

# Removes from HOST_FILE every line matching an entry of HOSTNAME
# (ignores differences in whitespace)
off() {
  local tmp
  tmp=$(mktemp) || return 1
  awk '
    function norm(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/[ \t]+/, " ", s); return s }
    NR == FNR { k = norm($0); if (k != "") entries[k] = 1; next }
    !(norm($0) in entries)
  ' <(printf '%s\n' "$HOSTNAME") "$HOST_FILE" > "$tmp" || { rm -f "$tmp"; return 1; }
  cat "$tmp" > "$HOST_FILE"
  rm -f "$tmp"
}

on() {
  off
  printf '%s\n' "$HOSTNAME" | sed '/^[[:space:]]*$/d' >> "$HOST_FILE"
  print_host_file
}

while getopts "fh" opt; do
  case "$opt" in
    f) off; exit 0 ;;            # -f sin valor
    h) print_usage; exit 1 ;;
  esac
done

on
exit 0