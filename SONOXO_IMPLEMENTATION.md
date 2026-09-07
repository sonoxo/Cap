# SONOXO local-first implementation

This fork can run as a self-hosted recording and sharing stack without requiring Cap Cloud or a paid API for the base product.

The implementation uses the repository's existing Docker Compose topology:

- Cap Web
- media server
- MySQL
- MinIO object storage

The desktop application can then point at the local server from **Settings > Cap Server URL**.

## Start

From the repository root:

```bash
bash scripts/sonoxo-local.sh
```

The bootstrap creates a gitignored `.env` on first run with generated local secrets, starts the full Compose stack, waits for the web app, and prints the local service URLs.

Default endpoints:

- Cap Web: `http://localhost:3000`
- MinIO API: `http://localhost:9000`
- MinIO console: `http://localhost:9001`

When outbound email is not configured, authentication login links are available from the Cap Web service logs:

```bash
docker compose logs cap-web
```

## Operational commands

```bash
# service status
docker compose ps

# application logs
docker compose logs -f cap-web media-server

# stop services while keeping data
docker compose down

# stop and delete local database/object-storage volumes
docker compose down -v
```

## Data ownership

MySQL and MinIO data live in Docker volumes defined by the upstream Compose stack. The bootstrap does not add a hosted storage dependency and does not configure third-party analytics or AI providers automatically.

Do not commit `.env`. It contains local database, object-storage, authentication, encryption, and webhook secrets.

## Production boundary

The bootstrap is for an operator-controlled local or development installation. Before exposing Cap to the public internet, configure real public URLs, TLS, durable backups, email/authentication providers as required, firewall/network policy, strong secret management, and production-grade object storage.

## Upstream compatibility

This implementation intentionally leaves the upstream application architecture intact. It adds a bootstrap/operations layer rather than forking the recorder, editor, web application, database schema, or media pipeline, which keeps future upstream synchronization practical.
