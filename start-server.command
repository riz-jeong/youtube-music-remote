#!/bin/bash

set -Eeuo pipefail

# Finder starts Terminal with a smaller PATH than an interactive shell.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")"

fail() {
  printf '\nError: %s\n' "$1" >&2
  if [[ -t 0 ]]; then
    read -r -p 'Press Enter to close this window... ' _
  fi
  exit 1
}

show_addresses() {
  printf '\nMac:    http://localhost:8080\n'
  local lan_ip='' interface api_host
  api_host=${api_upstream%:*}
  if [[ "$api_host" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
    lan_ip=$api_host
  else
    interface=$(route -n get default 2>/dev/null |
      awk '$1 == "interface:" { print $2; exit }' || true)
    [[ "$interface" == en* ]] || interface=''
    for interface in en0 en1 "$interface"; do
      [[ -n "$interface" ]] || continue
      lan_ip=$(ipconfig getifaddr "$interface" 2>/dev/null || true)
      [[ -n "$lan_ip" ]] && break
    done
  fi
  if [[ -n "$lan_ip" ]]; then
    printf 'iPhone: http://%s:8080\n' "$lan_ip"
  else
    printf 'iPhone: http://<Mac Wi-Fi IP>:8080\n'
  fi
}

command -v caddy >/dev/null || fail 'Caddy is missing. Install Caddy, then double-click this file again.'

if command -v yarn >/dev/null; then
  yarn_cmd=(yarn)
elif command -v corepack >/dev/null; then
  yarn_cmd=(corepack yarn)
else
  fail 'Yarn/Corepack is missing. Run: npm install -g corepack && corepack enable'
fi

api_upstream=${DESKTOP_API_UPSTREAM:-}
if [[ -z "$api_upstream" ]]; then
  api_upstream=$(lsof -nP -iTCP:26538 -sTCP:LISTEN -Fn 2>/dev/null |
    awk 'substr($0, 1, 1) == "n" { print substr($0, 2); exit }' || true)
  [[ -n "$api_upstream" ]] || fail 'Desktop API Server is not listening on port 26538. Enable its plugin first.'
  case "$api_upstream" in
    '*:26538'|'0.0.0.0:26538'|'[::]:26538') api_upstream='127.0.0.1:26538' ;;
  esac
fi

printf 'Desktop API: %s\n' "$api_upstream"

if [[ ! -x node_modules/.bin/expo ]]; then
  printf 'Installing dependencies...\n'
  "${yarn_cmd[@]}" install --immutable || fail 'Dependency installation failed.'
fi

printf 'Building the web app...\n'
EXPO_PUBLIC_SAME_ORIGIN_API=true "${yarn_cmd[@]}" expo export -p web || fail 'Web build failed.'
[[ -f dist/index.html ]] || fail 'Web build did not create dist/index.html.'

if lsof -nP -iTCP:8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
  web_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8080/ || true)
  api_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8080/api/v1/queue || true)
  if [[ "$web_status" == 200 && "$api_status" =~ ^2[0-9][0-9]$ ]]; then
    printf 'The server is already running.\n'
    show_addresses
    if [[ -t 0 ]]; then
      read -r -p 'Press Enter to close this window... ' _
    fi
    exit 0
  fi
  fail 'Port 8080 is already in use, but the web app or API is not responding. Stop that server and try again.'
fi

export DESKTOP_API_UPSTREAM="$api_upstream"
show_addresses
printf '\nStarting Caddy. Keep this window open; press Control-C to stop.\n\n'
caddy run --config deploy/Caddyfile.lan || fail 'Caddy stopped with an error.'
