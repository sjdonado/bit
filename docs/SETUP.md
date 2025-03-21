## CLI

```
Usage: ./cli [options]
Options:
  --create-user=NAME     Create a new user with the given name
  --list-users           List all users
  --delete-user=USER_ID  Delete a user by ID
  --update-data          Download all required data files
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
- Crystal 1.12+
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

- Colima: cpu 1, mem 1
- SoC: Apple M3 Pro

```
~/p/bit> colima start --cpu 1 --memory 1
INFO[0000] starting colima
INFO[0000] runtime: docker
INFO[0001] starting ...                                  context=vm
INFO[0076] provisioning ...                              context=docker
INFO[0077] starting ...                                  context=docker
INFO[0077] done
~/p/bit> ./benchmark.cr
Setting up...
Waiting for the application to be ready...
Seeding the database...
Checking seed results...
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/slug6268
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/slug6268 for 59s using 30 connection(s)
[==============================================================================================] 59s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1113.53     384.47    1642.40
  Latency       27.13ms     6.87ms   246.27ms
  Latency Distribution
     50%    25.13ms
     75%    27.60ms
     90%    32.34ms
     95%    36.06ms
     99%    50.99ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 65268, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   308.80KB/s
Benchmark completed successfully.
Analyzing resource usage...
**** Resource Usage Statistics ****
  Measurements: 31
  Average CPU Usage: 30.49%
  Average Memory Usage: 64.82 MiB
  Peak CPU Usage: 34.12%
  Peak Memory Usage: 65.45 MiB
Cleanup completed. Resource usage data saved in resource_usage.txt
~/p/bit> cat resource_usage.txt
Timestamp       CPU(%)  Memory(MiB)
1742499555      0.0     61.76
1742499557      0.01    61.76
1742499559      26.73   65.13
1742499561      32.59   65.16
1742499563      32.66   65.42
1742499565      33.32   65.45
1742499567      31.84   65.2
1742499569      33.01   65.4
1742499571      32.56   65.23
1742499573      32.86   65.23
1742499575      33.31   65.24
1742499577      33.0    65.06
1742499579      32.98   65.07
1742499581      33.42   64.93
1742499583      32.98   64.91
1742499585      32.85   64.93
1742499587      33.39   64.94
1742499589      32.88   64.95
1742499591      31.9    64.95
1742499593      34.12   65.21
1742499595      32.85   64.94
1742499597      32.95   64.89
1742499599      33.88   64.9
1742499601      31.93   64.89
1742499603      33.67   64.89
1742499605      32.62   64.89
1742499607      31.12   65.01
1742499609      31.04   64.77
1742499611      33.95   64.77
1742499613      32.3    64.68
1742499615      32.52   64.94
```
