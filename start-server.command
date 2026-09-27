#!/bin/bash

set -Eeuo pipefail

# Finder starts Terminal with a smaller PATH than an interactive shell.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cd "$(dirname "$0")"

fail() {
  printf '\n오류 / Error: %s\n' "$1" >&2
  if [[ -t 0 ]]; then
    read -r -p '닫으려면 Enter를 누르세요 / Press Enter to close... ' _
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

command -v caddy >/dev/null || fail 'Caddy가 없습니다. 설치 후 다시 실행하세요. / Install Caddy and try again.'

if command -v yarn >/dev/null; then
  yarn_cmd=(yarn)
elif command -v corepack >/dev/null; then
  yarn_cmd=(corepack yarn)
else
  fail 'Yarn/Corepack이 없습니다. 실행하세요 / Run: npm install -g corepack && corepack enable'
fi

api_upstream=${DESKTOP_API_UPSTREAM:-}
if [[ -z "$api_upstream" ]]; then
  api_upstream=$(lsof -nP -iTCP:26538 -sTCP:LISTEN -Fn 2>/dev/null |
    awk 'substr($0, 1, 1) == "n" { print substr($0, 2); exit }' || true)
  [[ -n "$api_upstream" ]] || fail '데스크톱 API 서버가 26538 포트에서 실행 중이지 않습니다. 플러그인을 켜세요. / Enable the desktop API Server plugin.'
  case "$api_upstream" in
    '*:26538'|'0.0.0.0:26538'|'[::]:26538') api_upstream='127.0.0.1:26538' ;;
  esac
fi

printf '데스크톱 API / Desktop API: %s\n' "$api_upstream"

if [[ ! -x node_modules/.bin/expo ]]; then
  printf '의존성 설치 중... / Installing dependencies...\n'
  "${yarn_cmd[@]}" install --immutable || fail '의존성 설치에 실패했습니다. / Dependency installation failed.'
fi

printf '웹 앱 빌드 중... / Building the web app...\n'
EXPO_PUBLIC_SAME_ORIGIN_API=true "${yarn_cmd[@]}" expo export -p web || fail '웹 빌드에 실패했습니다. / Web build failed.'
[[ -f dist/index.html ]] || fail '웹 빌드에서 dist/index.html을 만들지 못했습니다. / dist/index.html is missing.'

if lsof -nP -iTCP:8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
  web_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8080/ || true)
  api_status=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 http://localhost:8080/api/v1/queue || true)
  if [[ "$web_status" == 200 && "$api_status" =~ ^2[0-9][0-9]$ ]]; then
    printf '서버가 이미 실행 중입니다. / The server is already running.\n'
    show_addresses
    if [[ -t 0 ]]; then
      read -r -p '닫으려면 Enter를 누르세요 / Press Enter to close... ' _
    fi
    exit 0
  fi
  fail '8080 포트를 사용 중이지만 웹 앱 또는 API가 응답하지 않습니다. 기존 서버를 종료하고 다시 실행하세요. / Stop the server using port 8080 and try again.'
fi

export DESKTOP_API_UPSTREAM="$api_upstream"
show_addresses
printf '\nCaddy 시작 중입니다. 이 창을 열어 두세요. 중지하려면 Control-C를 누르세요.\nStarting Caddy. Keep this window open; press Control-C to stop.\n\n'
caddy run --config deploy/Caddyfile.lan || fail 'Caddy가 오류로 종료됐습니다. / Caddy stopped with an error.'
