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
- Crystal 1.21.1+
- Shards package manager
- SQLite3

### Install Dependencies
- linux
```bash
sudo apt-get update && sudo apt-get install -y crystal libssl-dev libsqlite3-dev
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

ENV=production shards build bit --release --no-debug
crystal spec e2e
```

## Benchmark

### Run

```
ENV=production shards build --release --no-debug
./bin/benchmark
```

Optional environment variables: `BENCHMARK_REQUESTS`, `BENCHMARK_CONNECTIONS`, and `BENCHMARK_DISABLE_KEEP_ALIVES` (`true` by default).

### Output

Machine: 10-core Apple M5 MacBook Pro. Memory: 32GB. macOS: 27.0.1. Crystal: 1.21.1. The run with the median Reqs/sec out of three consecutive runs.

```
Starting benchmark with 100000 requests using 125 connections...
Statistics        Avg      Stdev        Max
  Reqs/sec     21141.19    3261.06   26113.29
  Latency        5.91ms     1.41ms    25.77ms
  Latency Distribution
     50%     5.64ms
     75%     6.96ms
     90%     7.83ms
     95%     8.50ms
     99%    12.04ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     6.87MB/s

Click tracking drained: 100000/100000 clicks recorded.
Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 8
  Average CPU Usage: 52.95%
  Average Memory Usage: 32.14 MiB
  Peak CPU Usage: 90.4%
  Peak Memory Usage: 43.75 MiB
```

The benchmark validates that every redirect's asynchronous click record reaches SQLite. Earlier results measured redirect responses without verifying click delivery and are not directly comparable.
