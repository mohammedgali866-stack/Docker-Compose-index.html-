# Docker-Compose-index.html

# Docker: Standalone vs. Docker Compose Guide

---

## 1. Core Concept Overview

                      +-----------------------------------+
                      |       Your Application Stack      |
                      |   [ App Container ] + [ DB Container ]  |
                      +-----------------------------------+
                                        |
               +------------------------+------------------------+
               |                                                 |
               v                                                 v
   [ Imperative Approach ]                             [ Declarative Approach ]
   Manual / Scripted Setup                             Automated Orchestration
   (Without Docker Compose)                            (With Docker Compose)

---

## 2. Docker Architecture Components

* app Service
  - Responsibility: Custom web server running on port 8080:80
  - Custom Dockerfile Required? YES (Builds custom code into myapp:latest)

* db Service
  - Responsibility: PostgreSQL database engine
  - Custom Dockerfile Required? NO (Pulled directly from Docker Hub as postgres:16)

* pgdata Volume
  - Responsibility: Preserves database storage across container restarts
  - Custom Dockerfile Required? NO (Managed dynamically by Docker Engine)

* Network
  - Responsibility: Enables direct inter-container communication using service names
  - Custom Dockerfile Required? NO (Managed dynamically by Docker Engine)

---

## 3. Option A: Running WITH Docker Compose

In this setup, project dependencies, networks, and volumes are declaratively defined inside a single configuration file.

### Required File Structure

my-project/
├── index.html
├── Dockerfile
├── .dockerignore
└── docker-compose.yml

### File Definitions

index.html
```html
<!DOCTYPE html>
<html>
  <body>
    <h1>Hello World from App Container!</h1>
  </body>
</html>

Dockerfile
---------------
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80

.dockerignore
--------------
.git
.gitignore
Dockerfile
docker-compose.yml

docker-compose.yml 
------------------
services:
  app:
    image: myapp:latest
    build: .             # Automatically builds the local Dockerfile
    ports:
      - "8080:80"

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:


Command Execution Order 
-----------------------
# Step 1: Build the image and start the full multi-container stack in detached mode
docker compose up -d --build

# Step 2: Verify both running services
docker compose ps

# Step 3: Test access to the web server
curl http://localhost:8080

# Step 4: Tear down the stack (preserves persistent volumes)
docker compose down


4. Option B: Running WITHOUT Docker Compose

Without Compose, every network, volume, and container lifecycle operation must be manually managed using imperative shell scripts.
Required File Structure

my-project-no-compose/
├── index.html
├── Dockerfile
├── .dockerignore
├── run.sh
└── stop.sh
File Definitions

run.sh
------
#!/usr/bin/env bash
set -euo pipefail

# Define variables
NETWORK="myapp-net"
VOLUME="pgdata"
APP_IMAGE="myapp:latest"
APP_CONTAINER="app"
DB_CONTAINER="db"

# 1. Create an isolated virtual network (if it doesn't already exist)
docker network create "$NETWORK" 2>/dev/null || true

# 2. Create the persistent storage volume
docker volume create "$VOLUME"

# 3. Build the custom web app image
docker build -t "$APP_IMAGE" .

# 4. Run the PostgreSQL container
docker run -d \
  --name "$DB_CONTAINER" \
  --network "$NETWORK" \
  --network-alias db \
  -v "${VOLUME}:/var/lib/postgresql/data" \
  -e POSTGRES_PASSWORD=secret \
  postgres:16

# 5. Run the custom web app container
docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK" \
  --network-alias app \
  -p 8080:80 \
  "$APP_IMAGE"

echo "App running at: http://localhost:8080"
echo "DB accessible from app container at: db:5432"


stop.sh
--------
#!/usr/bin/env bash
set -euo pipefail

# Force remove the running containers
docker rm -f app db 2>/dev/null || true

# Remove the isolated virtual network
docker network rm myapp-net 2>/dev/null || true

# Note: The "pgdata" volume is deliberately preserved to prevent data loss.

5. Side-by-Side Comparison

    NETWORKING

        Without Docker Compose (run.sh):
        Explicit "docker network create" and "--network" flags required.

        With Docker Compose (docker-compose.yml):
        AUTOMATIC — Creates a default dedicated bridge network.

    VOLUME CREATION

        Without Docker Compose (run.sh):
        Explicit "docker volume create" call required.

        With Docker Compose (docker-compose.yml):
        AUTOMATIC — Provisions declared volumes before runtime.

    DNS / HOSTNAMES

        Without Docker Compose (run.sh):
        Must manually set "--network-alias db" on containers.

        With Docker Compose (docker-compose.yml):
        AUTOMATIC — Containers map directly to service names ("db").

    CONTAINER LIFECYCLE

        Without Docker Compose (run.sh):
        Must write individual "docker run" and "docker rm" steps.

        With Docker Compose (docker-compose.yml):
        UNIFIED — Handled entirely by "docker compose up / down".

