[![Docker Pulls](https://img.shields.io/docker/pulls/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Image Size](https://img.shields.io/docker/image-size/sjdonado/bit/latest)](https://hub.docker.com/r/sjdonado/bit)

## Features

- Minimal tracking setup: Country, browser, OS, referer. No cookies or persistent tracking mechanisms are used beyond what's available from a basic client's request.
- Includes `X-Forwarded-For` header.
- Multiple users are supported via API key authentication. Create, list and delete keys via the [CLI](docs/SETUP.md#cli).
- Easy to extend, Ruby on Rails inspired setup.
- Auto update UA regexes and GeoLite2 database.

## Why bit?

**Fast:** **11k req/sec**, latency 11ms, 40MiB avg memory usage (100k requests using 125 connections, [benchmark](docs/SETUP.md#benchmark)).

**Lightweight:** Minimal dependencies, image size under 20 MiB, memory usage under 60 MiB at peak.

**Self-hosted:** [Dokku](docs/SETUP.md#dokku), [Docker Compose](docs/SETUP.md#docker-compose).

**Production ready:** Feature-complete by design, simple and reliable without unnecessary bloat. Bug fixes will continue, but new features aren't planned.

## Run It Anywhere

All images available on [Docker Hub](https://hub.docker.com/r/sjdonado/bit/tags).

### Docker

```bash
docker run \
    --name bit \
    -p 4000:4000 \
    -e ENV="production" \
    -e DATABASE_URL="sqlite3://./sqlite/data.db" \
    -e APP_URL="http://localhost:4000" \
    -e ADMIN_NAME="Admin" \
    -e ADMIN_API_KEY=$(openssl rand -base64 32) \
    sjdonado/bit

# Create a new user
# docker exec -it bit cli --create-user=Admin
```

### Docker Compose

```bash
docker-compose up

# Optional: Generate an api key
# docker-compose exec -it app cli --create-user=Admin
```

### Dokku

- Dockerfile
```dockerfile
FROM sjdonado/bit
```

- Over ssh

```bash
dokku apps:create bit

dokku domains:set bit bit.yourdomain.com
dokku letsencrypt:enable bit

dokku storage:ensure-directory bit-sqlite
dokku storage:mount bit /var/lib/dokku/data/storage/bit-sqlite:/usr/src/app/sqlite/

dokku config:set bit DATABASE_URL="sqlite3://./sqlite/data.db" APP_URL=https://bit.yourdomain.com ADMIN_NAME=Admin ADMIN_API_KEY=$(openssl rand -base64 32)

dokku ports:add bit http:80:4000
dokku ports:add bit https:443:4000

# Create a new user
# dokku run bit cli --create-user=Admin
```

### Dokku (subnetwork)
Recommended for lower latency communication (no host network traversal)

```bash
  dokku network:create bit-net
  dokku network:set bit attach-post-create bit-net
  dokku network:set myapp attach-post-create bit-net
```

## Documentation
- [API Reference](https://sjdonado.github.io/bit/)
- [Local Development](docs/SETUP.md)

## Contributing
Found an issue or have a suggestion? Please follow our [contribution guidelines](CONTRIBUTING.md).
