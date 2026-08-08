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
  Reqs/sec      3939.43    1358.64    6784.10
  Latency       31.87ms      3.66ms      67.04ms
  Latency Distribution
     50%    32.07ms
     75%    33.55ms
     90%    35.06ms
     95%    36.29ms
     99%    45.38ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     1.27MB/s

Click tracking drained: 100000/100000 clicks recorded.
Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 29
  Average CPU Usage: 68.7%
  Average Memory Usage: 40.77 MiB
  Peak CPU Usage: 79.8%
  Peak Memory Usage: 46.8 MiB
```

The benchmark validates that every redirect's asynchronous click record reaches SQLite. Earlier results measured redirect responses without verifying click delivery and are not directly comparable.
