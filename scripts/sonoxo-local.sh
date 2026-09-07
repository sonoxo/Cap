#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

random_hex() {
  local bytes="$1"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$bytes"
  else
    od -An -N "$bytes" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

require docker
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required (docker compose)." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cat > .env <<EOF
CAP_URL=http://localhost:3000
S3_PUBLIC_URL=http://localhost:9000
CAP_PORT=3000
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
MYSQL_PASSWORD=$(random_hex 24)
MYSQL_ROOT_PASSWORD=$(random_hex 24)
MINIO_ROOT_USER=cap-admin
MINIO_ROOT_PASSWORD=$(random_hex 24)
DATABASE_ENCRYPTION_KEY=$(random_hex 32)
NEXTAUTH_SECRET=$(random_hex 32)
MEDIA_SERVER_WEBHOOK_SECRET=$(random_hex 32)
RESEND_API_KEY=
RESEND_FROM_DOMAIN=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APPLE_CLIENT_ID=
APPLE_CLIENT_SECRET=
EOF
  echo "Created .env with local-only generated secrets."
else
  echo "Using existing .env; no secrets were overwritten."
fi

CAP_PORT_VALUE="$(awk -F= '$1=="CAP_PORT" {print $2}' .env | tail -1)"
CAP_PORT_VALUE="${CAP_PORT_VALUE:-3000}"
MINIO_CONSOLE_PORT_VALUE="$(awk -F= '$1=="MINIO_CONSOLE_PORT" {print $2}' .env | tail -1)"
MINIO_CONSOLE_PORT_VALUE="${MINIO_CONSOLE_PORT_VALUE:-9001}"

echo "Starting Cap Web, media server, MySQL, and MinIO..."
docker compose up -d --build

echo "Waiting for Cap Web to become healthy..."
ready=0
for _ in $(seq 1 90); do
  if command -v curl >/dev/null 2>&1; then
    if curl -fsS "http://127.0.0.1:${CAP_PORT_VALUE}/" >/dev/null 2>&1; then
      ready=1
      break
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -q -O /dev/null "http://127.0.0.1:${CAP_PORT_VALUE}/"; then
      ready=1
      break
    fi
  else
    echo "Neither curl nor wget is available; skipping HTTP readiness probe."
    ready=1
    break
  fi
  sleep 2
done

if [[ "$ready" -ne 1 ]]; then
  echo "Cap did not become ready within 180 seconds." >&2
  docker compose ps
  echo "Inspect logs with: docker compose logs --tail=200 cap-web media-server" >&2
  exit 1
fi

echo
echo "Cap local stack is running."
echo "App:           http://localhost:${CAP_PORT_VALUE}"
echo "MinIO console: http://localhost:${MINIO_CONSOLE_PORT_VALUE}"
echo "Status:        docker compose ps"
echo "Login links:   docker compose logs cap-web"
echo "Stop:          docker compose down"
echo
echo "Base self-hosting does not require paid AI, email, or analytics providers."
