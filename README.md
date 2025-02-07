[![Docker Pulls](https://img.shields.io/docker/pulls/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Stars](https://img.shields.io/docker/stars/sjdonado/bit.svg)](https://hub.docker.com/r/sjdonado/bit)
[![Docker Image Size](https://img.shields.io/docker/image-size/sjdonado/bit/latest)](https://hub.docker.com/r/sjdonado/bit)

# Bit URL Shortener

Lightweight URL shortener service with minimal resource requirements. Average memory consumption is **20MB RAM** with container disk space under **50MB**.

Bit is highly performant, achieving over 850 requests per second with an average latency of just 118ms. For detailed benchmark results, see [benchmark](docs/SETUP.md#benchmark).

## Quick Start
```bash
docker run -p 4000:4000 -e ADMIN_API_KEY=$(openssl rand -base64 32) sjdonado/bit:latest
```

## Minimum Requirements
- 50MB disk space
- 50MB RAM (20MB avg usage)
- x86_64 or ARM64 architecture

## Available Images

| Tag     | Architecture | Compressed Size | Uncompressed Size |
|---------|--------------|-----------------|-------------------|
| `latest`| linux/amd64  | 12.12 MB        | 32.3 MB           |
| `latest`| linux/arm64  | 12.8 MB         | 32.3 MB           |

## Documentation
- [API Reference](docs/API.md)
- [Advanced Setup](docs/SETUP.md)

## Contributing
Found an issue or have a suggestion? Please follow our [contribution guidelines](CONTRIBUTING.md).
