#!/usr/bin/env bash
set -euo pipefail

docker rm -f app db 2>/dev/null || true
docker network rm myapp-net 2>/dev/null || true
# Keep the named volume so data survives, same as Compose.
# To wipe Postgres data: docker volume rm pgdata
