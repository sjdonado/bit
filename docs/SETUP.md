## CLI

```
Usage: ./cli [options]
Options:
  --create-user=NAME     Create a new user with the given name
  --list-users           List all users
  --delete-user=USER_ID  Delete a user by ID
  --update-parsers       Download all required data files
```

## Local Development

### Requirements
- Crystal 1.18+
- Shards package manager
- SQLite3

### Install Dependencies
- linux
```bash
sudo apt-get update && sudo apt-get install -y crystal libssl-dev libsqlite3-dev
```

- macos
```bash
brew tap amberframework/micrate
brew install micrate
```

### Install Shards and Run

```bash
shards run bit
```

- Generate the `X-Api-Key`

```bash
shards run cli -- --create-user=Admin
```

- Run tests

```bash
ENV=test crystal spec
```

## Benchmark

### Run

```
shards build --release --no-debug
./bin/benchmark
```

Optional environment variables: `BENCHMARK_REQUESTS`, `BENCHMARK_CONNECTIONS`, and `BENCHMARK_DISABLE_KEEP_ALIVES` (`true` by default).

### Output

Chip: Apple M4 Pro. Memory: 24GB. Crystal: 1.21.0.

```
Starting benchmark with 100000 requests using 125 connections...
Statistics        Avg      Stdev        Max
  Reqs/sec      3460.44     974.82    6791.57
  Latency       36.17ms      9.21ms     267.24ms
  Latency Distribution
     50%    36.05ms
     75%    37.40ms
     90%    39.04ms
     95%    41.90ms
     99%    48.50ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     1.12MB/s

Click tracking drained: 100000/100000 clicks recorded.
Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 32
  Average CPU Usage: 70.38%
  Average Memory Usage: 40.88 MiB
  Peak CPU Usage: 80.7%
  Peak Memory Usage: 46.7 MiB
```

The benchmark validates that every redirect's asynchronous click record reaches SQLite. Earlier results measured redirect responses without verifying click delivery and are not directly comparable.
