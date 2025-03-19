[![Docker Pulls](https://img.shields.io/docker/pulls/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Stars](https://img.shields.io/docker/stars/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Image Size](https://img.shields.io/docker/image-size/sjdonado/bit/latest)](https://hub.docker.com/r/sjdonado/bit)

Lightweight URL shortener API service with minimal resource requirements. Average memory consumption is under **20MiB** and single CPU core consumption under 20%.

Performance: Avg **3K reqs/sec**, latency 56ms (100K requests using 100 connections, [benchmark](docs/SETUP.md#benchmark)).

Self-hosted with [Dokku](docs/SETUP.md#dokku) and [Docker Compose](docs/SETUP.md#docker-compose).

Images available on [Docker Hub](https://hub.docker.com/r/sjdonado/bit/tags).

## Why bit?
It is feature-complete by design. Its strength lies in simplicity, reliable without unnecessary bloat. Bug fixes will continue, but new features aren't planned.

- Minimal tracking setup: Country, browser, os, referer. No cookies or persistent tracking mechanisms are used beyond what's available from a basic client's request.
- Flexible request forwarding system passes client context to destinations via standard `X-Forwarded-For` and `User-Agent` headers, enabling advanced tracking and integration capabilities when needed.
- Multiple users are supported via API key authentication. Create, list and delete via the [CLI](docs/SETUP.md#cli).

## Minimum Requirements
- 100MB disk space
- 50MiB RAM
- x86_64 or ARM64

## Documentation
- [API Reference](docs/API.md)
- [Setup](docs/SETUP.md)

## Contributing
Found an issue or have a suggestion? Please follow our [contribution guidelines](CONTRIBUTING.md).
