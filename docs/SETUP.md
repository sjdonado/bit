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
shards build --release --no-debug --progress --stats
shards run benchmark
```

### Output

Chip: Apple M4 Pro. Memory: 24GB

```
1762075350 ~/p/bit> shards build --release --no-debug --progress --stats
                    shards run benchmark
Dependencies are satisfied
Building: bit
Parse:                             00:00:00.000652375 (   1.17MB)
Semantic (top level):              00:00:00.419246250 ( 163.45MB)
Semantic (new):                    00:00:00.001636125 ( 163.45MB)
Semantic (type declarations):      00:00:00.019569792 ( 179.45MB)
Semantic (abstract def check):     00:00:00.009145125 ( 195.45MB)
Semantic (restrictions augmenter): 00:00:00.008421709 ( 195.45MB)
Semantic (ivars initializers):     00:00:00.019696584 ( 211.45MB)
Semantic (cvars initializers):     00:00:00.106829666 ( 211.50MB)
Semantic (main):                   00:00:00.649298375 ( 499.88MB)
Semantic (cleanup):                00:00:00.000765250 ( 499.88MB)
Semantic (recursive struct check): 00:00:00.000752250 ( 499.88MB)
Codegen (crystal):                 00:00:00.521307417 ( 532.38MB)
Codegen (bc+obj):                  00:00:00.143842542 ( 532.38MB)
Codegen (linking):                 00:00:00.236228750 ( 532.38MB)

Macro runs:
 - /opt/homebrew/Cellar/crystal/1.18.2/share/crystal/src/ecr/process.cr: reused previous compilation (00:00:00.003593375)

Codegen (bc+obj):
 - all previous .o files were reused
Building: cli
Parse:                             00:00:00.000053291 (   1.17MB)
Semantic (top level):              00:00:00.323534167 ( 163.45MB)
Semantic (new):                    00:00:00.001705500 ( 163.45MB)
Semantic (type declarations):      00:00:00.018311958 ( 179.45MB)
Semantic (abstract def check):     00:00:00.007766750 ( 195.45MB)
Semantic (restrictions augmenter): 00:00:00.005686667 ( 195.45MB)
Semantic (ivars initializers):     00:00:00.011239792 ( 211.45MB)
Semantic (cvars initializers):     00:00:00.100870833 ( 211.50MB)
Semantic (main):                   00:00:00.285426750 ( 371.62MB)
Semantic (cleanup):                00:00:00.000369875 ( 371.62MB)
Semantic (recursive struct check): 00:00:00.000570917 ( 371.62MB)
Codegen (crystal):                 00:00:00.317534875 ( 387.88MB)
Codegen (bc+obj):                  00:00:00.097321417 ( 387.88MB)
Codegen (linking):                 00:00:00.095931000 ( 387.88MB)

Codegen (bc+obj):
 - all previous .o files were reused
Building: benchmark
Parse:                             00:00:00.000228500 (   1.17MB)
Semantic (top level):              00:00:00.242174458 ( 147.78MB)
Semantic (new):                    00:00:00.000863333 ( 147.78MB)
Semantic (type declarations):      00:00:00.011527792 ( 147.78MB)
Semantic (abstract def check):     00:00:00.031242333 ( 147.78MB)
Semantic (restrictions augmenter): 00:00:00.003593583 ( 147.78MB)
Semantic (ivars initializers):     00:00:00.006753667 ( 147.78MB)
Semantic (cvars initializers):     00:00:00.028373834 ( 195.78MB)
Semantic (main):                   00:00:00.152039542 ( 243.83MB)
Semantic (cleanup):                00:00:00.000249084 ( 243.83MB)
Semantic (recursive struct check): 00:00:00.000460417 ( 243.83MB)
Codegen (crystal):                 00:00:00.075461000 ( 259.83MB)
Codegen (bc+obj):                  00:00:04.834914333 ( 259.83MB)
Codegen (linking):                 00:00:00.119920416 ( 259.83MB)

Codegen (bc+obj):
 - no previous .o files were reused
Dependencies are satisfied
Building: benchmark
Executing: benchmark
Cleaning up benchmark database...
Deleted existing database: ./sqlite/data.benchmark.db
Database cleanup completed.
Running database migrations...
Migrating db, current version: 0, target: 20250319192003
OK   20240512214223_create_links.sql
OK   20240512225208_add_slug_index_to_links.sql
OK   20240513115731_create_users.sql
OK   20240513130054_add_api_key_index_to_users.sql
OK   20240711224103_create_clicks.sql
OK   20240714215409_update_slug_size_links.sql
OK   20250316102350_add_country_to_clicks.sql
OK   20250316111734_replace_unkwown_with_null.sql
OK   20250318072657_replace_slug_index_with_covering_index.sql
OK   20250319192003_convert_all_tables_text_ids_to_integer.sql
Migrations completed successfully.
Seeding benchmark database...
Database seeded successfully.
Starting application: ./bit...
Application output will be saved to: app_output.log
Application started with PID: 11638
Using database: ./sqlite/data.benchmark.db
Checking if server is ready at http://localhost:4001...
.Server is ready!
Fetching links from API...
Selected link: http://localhost:4001/slug9391

Starting benchmark with 100000 requests...
Bombarding http://localhost:4001/slug9391 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [============================================================================] 100.00% 11078/s 9s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec     11427.28    8889.68   30270.91
  Latency       11.02ms     6.55ms    53.91ms
  Latency Distribution
     50%     1.85ms
     75%     5.37ms
     90%    39.36ms
     95%    39.87ms
     99%    42.66ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     3.08MB/s

Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 12
  Average CPU Usage: 71.5%
  Average Memory Usage: 39.8 MiB
  Peak CPU Usage: 100.0%
  Peak Memory Usage: 53.41 MiB

**** Files Generated ****
  Resource stats: resource_usage.log
  Application log: app_output.log
  Database: ./sqlite/data.benchmark.db

Stopping application...
Application stopped.
```
