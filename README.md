[![Docker Pulls](https://img.shields.io/docker/pulls/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Stars](https://img.shields.io/docker/stars/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Image Size](https://img.shields.io/docker/image-size/sjdonado/bit/latest)](https://hub.docker.com/r/sjdonado/bit)

Lightweight URL shortener (API-only) with minimal resource requirements. Avg memory consumption under pressure is around **60MiB**, avg CPU load 60%.

Highly performant: **6.6k req/sec**, latency 18.9ms (100k requests using 125 connections, [benchmark](docs/SETUP.md#benchmark)).

Self-hosted: [Dokku](docs/SETUP.md#dokku), [Docker Compose](docs/SETUP.md#docker-compose).

Images available on [Docker Hub](https://hub.docker.com/r/sjdonado/bit/tags).

## Why bit?
It is feature-complete by design: simple and reliable without unnecessary bloat. Bug fixes will continue, but new features aren't planned.

- Minimal tracking setup: Country, browser, OS, referer. No cookies or persistent tracking mechanisms are used beyond what's available from a basic client's request.
- Includes `X-Forwarded-For` header.
- Multiple users are supported via API key authentication. Users can create, list and delete keys via the [CLI](docs/SETUP.md#cli).
- Easy to extend, Ruby on Rails-inspired setup.

## Minimum Requirements
- 100MB disk space
- 70MiB RAM
- x86_64 or ARM64

## Documentation
- [API Reference](docs/API.md)
- [Setup](docs/SETUP.md)

## Contributing
Found an issue or have a suggestion? Please follow our [contribution guidelines](CONTRIBUTING.md).
