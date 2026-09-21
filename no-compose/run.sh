#!/usr/bin/env bash
set -euo pipefail

# Same stack as docker-compose.yml, without Compose:
#   app  -> myapp:latest, 8080:80
#   db   -> postgres:16, volume pgdata
#
# Compose would create a project network and named volume for you.
# Here you do that by hand so the two containers can reach each other.

NETWORK=myapp-net
VOLUME=pgdata
APP_IMAGE=myapp:latest
APP_CONTAINER=app
DB_CONTAINER=db

docker network create "$NETWORK" 2>/dev/null || true
docker volume create "$VOLUME"

docker build -t "$APP_IMAGE" .

# Postgres refuses to start without POSTGRES_PASSWORD.
# Compose example omitted it; you still need it at runtime.
docker run -d \
  --name "$DB_CONTAINER" \
  --network "$NETWORK" \
  --network-alias db \
  -v "${VOLUME}:/var/lib/postgresql/data" \
  -e POSTGRES_PASSWORD=secret \
  postgres:16

docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK" \
  --network-alias app \
  -p 8080:80 \
  "$APP_IMAGE"

echo "app: http://localhost:8080"
echo "db hostname from the app container: db:5432"
