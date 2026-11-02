#!/bin/bash
HELP="""
Usage: $0 [-f] [-s] [-h]
Options:
  -h    Show this help message
  -f    Turn off local hostnames
  -s    Show whether local hostnames are applied
"""


HOSTNAME="""
10.10.100.131    sale-api.newzone.com.py
10.10.100.131    products-api.newzone.com.py
10.10.100.131    cashbox-api.newzone.com.py
10.10.100.131    cashbox-payment-methods-api.newzone.com.py
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

# Reports whether every HOSTNAME entry is present in HOST_FILE
status() {
  local total=0 found=0 line norm
  local hosts
  hosts=$(sed -E 's/^[[:space:]]+|[[:space:]]+$//g; s/[[:space:]]+/ /g' "$HOST_FILE")
  while IFS= read -r line; do
    norm=$(printf '%s' "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g; s/[[:space:]]+/ /g')
    [ -z "$norm" ] && continue
    total=$((total + 1))
    if printf '%s\n' "$hosts" | grep -qxF -- "$norm"; then
      found=$((found + 1))
    fi
  done <<< "$HOSTNAME"

  if [ "$found" -eq "$total" ]; then
    echo "Applied ($found/$total)"
    return 0
  elif [ "$found" -eq 0 ]; then
    echo "Not applied (0/$total)"
  else
    echo "Partially applied ($found/$total)"
  fi
  return 1
}

while getopts "fhs" opt; do
  case "$opt" in
    f) off; exit 0 ;;            # -f sin valor
    s) status; exit $? ;;
    h) print_usage; exit 1 ;;
  esac
done

on
exit 0