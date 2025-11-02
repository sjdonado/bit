## CLI

```
Usage: ./cli [options]
Options:
  --create-user=NAME     Create a new user with the given name
  --list-users           List all users
  --delete-user=USER_ID  Delete a user by ID
  --update-parsers       Download all required data files
```

## Run It Anywhere

### Docker Compose

```bash
docker-compose up

# Optional: Generate an api key
# docker-compose exec -it app cli --create-user=Admin
```

### Docker CLI

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

### Dokku

```dockerfile
FROM sjdonado/bit
```

```bash
dokku apps:create bit

dokku domains:set bit bit.donado.co
dokku letsencrypt:enable bit

dokku storage:ensure-directory bit-sqlite
dokku storage:mount bit /var/lib/dokku/data/storage/bit-sqlite:/usr/src/app/sqlite/

dokku config:set bit DATABASE_URL="sqlite3://./sqlite/data.db" APP_URL=https://bit.donado.co ADMIN_NAME=Admin ADMIN_API_KEY=$(openssl rand -base64 32)

dokku ports:add bit http:80:4000
dokku ports:add bit https:443:4000

# Create a new user
# dokku run bit cli --create-user=Admin
```

### Dokku (same network)
Recommended for lower latency communication (no host network traversal)

```bash
  dokku network:create bit-net
  dokku network:set bit attach-post-create bit-net
  dokku network:set myapp attach-post-create bit-net
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

- Dry run

```
1762068811 ~/p/bit> shards build --release --no-debug --progress --stats
Dependencies are satisfied
Building: bit
Parse:                             00:00:00.000041417 (   1.17MB)
Semantic (top level):              00:00:00.407816208 ( 163.45MB)
Semantic (new):                    00:00:00.001814125 ( 163.45MB)
Semantic (type declarations):      00:00:00.019943333 ( 179.45MB)
Semantic (abstract def check):     00:00:00.007606542 ( 195.45MB)
Semantic (restrictions augmenter): 00:00:00.006390917 ( 195.45MB)
Semantic (ivars initializers):     00:00:00.012892709 ( 211.45MB)
Semantic (cvars initializers):     00:00:00.101427125 ( 211.50MB)
Semantic (main):                   00:00:00.639027292 ( 499.88MB)
Semantic (cleanup):                00:00:00.000513000 ( 499.88MB)
Semantic (recursive struct check): 00:00:00.000625542 ( 499.88MB)
Codegen (crystal):                 00:00:00.514694833 ( 532.38MB)
Codegen (bc+obj):                  00:00:14.734378459 ( 532.38MB)
Codegen (linking):                 00:00:00.308837000 ( 532.38MB)

Macro runs:
 - /opt/homebrew/Cellar/crystal/1.18.2/share/crystal/src/ecr/process.cr: reused previous compilation (00:00:00.003361958)

Codegen (bc+obj):
 - no previous .o files were reused
Building: cli
Parse:                             00:00:00.000057625 (   1.17MB)
Semantic (top level):              00:00:00.378950750 ( 163.45MB)
Semantic (new):                    00:00:00.001392542 ( 163.45MB)
Semantic (type declarations):      00:00:00.017725458 ( 179.45MB)
Semantic (abstract def check):     00:00:00.007331291 ( 195.45MB)
Semantic (restrictions augmenter): 00:00:00.006174250 ( 195.45MB)
Semantic (ivars initializers):     00:00:00.012456209 ( 211.45MB)
Semantic (cvars initializers):     00:00:00.101925250 ( 211.50MB)
Semantic (main):                   00:00:00.283259791 ( 371.62MB)
Semantic (cleanup):                00:00:00.000385375 ( 371.62MB)
Semantic (recursive struct check): 00:00:00.000574250 ( 371.62MB)
Codegen (crystal):                 00:00:00.318639083 ( 387.88MB)
Codegen (bc+obj):                  00:00:00.090703209 ( 387.88MB)
Codegen (linking):                 00:00:00.100725000 ( 387.88MB)

Codegen (bc+obj):
 - all previous .o files were reused
Building: benchmark
Parse:                             00:00:00.000210708 (   1.17MB)
Semantic (top level):              00:00:00.259058375 ( 147.78MB)
Semantic (new):                    00:00:00.000878709 ( 147.78MB)
Semantic (type declarations):      00:00:00.012123625 ( 147.78MB)
Semantic (abstract def check):     00:00:00.032016792 ( 147.78MB)
Semantic (restrictions augmenter): 00:00:00.004018334 ( 147.78MB)
Semantic (ivars initializers):     00:00:00.006835041 ( 147.78MB)
Semantic (cvars initializers):     00:00:00.031038959 ( 195.78MB)
Semantic (main):                   00:00:00.157428625 ( 243.83MB)
Semantic (cleanup):                00:00:00.000264416 ( 243.83MB)
Semantic (recursive struct check): 00:00:00.000380166 ( 243.83MB)
Codegen (crystal):                 00:00:00.079188459 ( 259.83MB)
Codegen (bc+obj):                  00:00:04.807389083 ( 259.83MB)
Codegen (linking):                 00:00:00.098161042 ( 259.83MB)

Codegen (bc+obj):
 - no previous .o files were reused
1762068874 ~/p/bit> shards run benchmark
Dependencies are satisfied
Building: benchmark
Executing: benchmark
Starting application: ./bit...
Application output will be saved to: app_output.log
Application started with PID: 12693
Checking if server is ready at http://localhost:4000...
.Server is ready!
Seeding database...
Database seeded successfully.
Fetching links from API...
Selected link: http://localhost:4000/slug9623

Starting benchmark with 100000 requests...
Bombarding http://localhost:4000/slug9623 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [===============================================================================================================================================================================================] 100.00% 11079/s 9s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec     11361.35    8907.62   28610.94
  Latency       11.09ms     6.66ms    52.76ms
  Latency Distribution
     50%     1.93ms
     75%     3.12ms
     90%    39.47ms
     95%    40.07ms
     99%    42.60ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     3.06MB/s

Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 12
  Average CPU Usage: 73.94%
  Average Memory Usage: 42.45 MiB
  Peak CPU Usage: 100.0%
  Peak Memory Usage: 56.02 MiB

**** Files Generated ****
  Resource stats: resource_usage.log
  Application log: app_output.log

Stopping application...
Application stopped.
```

- Second run

```
1762068874 ~/p/bit> shards run benchmark
Dependencies are satisfied
Building: benchmark
Executing: benchmark
Starting application: ./bit...
Application output will be saved to: app_output.log
Application started with PID: 12693
Checking if server is ready at http://localhost:4000...
.Server is ready!
Seeding database...
Database seeded successfully.
Fetching links from API...
Selected link: http://localhost:4000/slug9623

Starting benchmark with 100000 requests...
Bombarding http://localhost:4000/slug9623 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [===============================================================================================================================================================================================] 100.00% 11079/s 9s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec     11361.35    8907.62   28610.94
  Latency       11.09ms     6.66ms    52.76ms
  Latency Distribution
     50%     1.93ms
     75%     3.12ms
     90%    39.47ms
     95%    40.07ms
     99%    42.60ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     3.06MB/s

Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 12
  Average CPU Usage: 73.94%
  Average Memory Usage: 42.45 MiB
  Peak CPU Usage: 100.0%
  Peak Memory Usage: 56.02 MiB

**** Files Generated ****
  Resource stats: resource_usage.log
  Application log: app_output.log

Stopping application...
Application stopped.
1762068900 ~/p/bit> shards run benchmark
Dependencies are satisfied
Building: benchmark
Executing: benchmark
Starting application: ./bit...
Application output will be saved to: app_output.log
Application started with PID: 18421
Checking if server is ready at http://localhost:4000...
.Server is ready!
Seeding database...
Runtime error near line 1: UNIQUE constraint failed: users.api_key (19)
Runtime error near line 7: UNIQUE constraint failed: links.slug (19)
Warning: Database seeding failed. Continuing anyway...
Fetching links from API...
Selected link: http://localhost:4000/slug5911

Starting benchmark with 100000 requests...
Bombarding http://localhost:4000/slug5911 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [===============================================================================================================================================================================================] 100.00% 11080/s 9s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec     11213.27    8842.12   29594.78
  Latency       11.24ms     6.87ms    43.66ms
  Latency Distribution
     50%     1.96ms
     75%     3.01ms
     90%    40.02ms
     95%    41.06ms
     99%    42.58ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     3.02MB/s

Benchmark completed successfully.

**** Resource Usage Statistics ****
  Measurements: 12
  Average CPU Usage: 74.28%
  Average Memory Usage: 32.18 MiB
  Peak CPU Usage: 100.0%
  Peak Memory Usage: 40.88 MiB

**** Files Generated ****
  Resource stats: resource_usage.log
  Application log: app_output.log

Stopping application...
Application stopped.
```
