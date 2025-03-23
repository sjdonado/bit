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
Selected link for benchmarking: http://localhost:4000/slug8558
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/slug8558 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [==============================================================] 100.00% 7126/s 14s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      7233.84    1873.69   13200.45
  Latency       17.31ms     1.44ms    44.42ms
  Latency Distribution
     50%    17.11ms
     75%    18.36ms
     90%    19.75ms
     95%    20.64ms
     99%    22.72ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     1.97MB/s
Benchmark completed successfully.
Analyzing resource usage...
Timestamp       CPU(%)  Memory(MiB)
1742732558      0.04    50.07
1742732560      0.03    50.07
1742732562      88.02   79.78
1742732564      86.57   79.02
1742732566      89.27   79.3
1742732568      87.5    79.09
1742732570      88.88   79.12
1742732572      88.35   79.41
1742732574      88.88   79.44
1742732576      0.02    78.53

**** Resource Usage Statistics ****
  Measurements: 10
  Average CPU Usage: 61.76%
  Average Memory Usage: 73.38 MiB
  Peak CPU Usage: 89.27%
  Peak Memory Usage: 79.78 MiB
Cleanup completed. Resource usage data saved in resource_usage.txt
```
