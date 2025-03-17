[![Docker Pulls](https://img.shields.io/docker/pulls/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Stars](https://img.shields.io/docker/stars/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Image Size](https://img.shields.io/docker/image-size/sjdonado/bit/latest)](https://hub.docker.com/r/sjdonado/bit)

Lightweight URL shortener service with minimal resource requirements. Average memory consumption is under **20MiB** and single CPU core consumption under 30%.

bit is highly performant, achieving maximum **15.3K RPS** with a minimum latency of 48.89ms for 100K requests using 100 connections. For detailed benchmark results, see [benchmark](docs/SETUP.md#benchmark).

Images available on [Docker Hub](https://hub.docker.com/r/sjdonado/bit/tags).

## Why bit?
It is feature-complete by design. Its strength lies in simplicity, a reliable URL shortener without unnecessary bloat. Bug fixes will continue, but new features aren't planned.

- Minimal tracking setup: Country, browser, os, referer. No cookies or persistent tracking mechanisms are used beyond what's available from a basic client's request.
- Flexible request forwarding system passes client context (IP, user-agent) to destinations via standard `X-Forwarded-For` and `User-Agent` headers, enabling advanced tracking and integration capabilities when needed.
- Multiple users are supported via API key authentication. Create, list and delete via the [CLI](docs/SETUP.md#cli).

## Minimum Requirements
- 50MB disk space
- 50MB RAM (20MB avg usage)
- x86_64 or ARM64 architecture

## Documentation
- [API Reference](docs/API.md)
- [Setup](docs/SETUP.md)

## Contributing
Found an issue or have a suggestion? Please follow our [contribution guidelines](CONTRIBUTING.md).
