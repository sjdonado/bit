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
Selected link for benchmarking: http://localhost:4000/slug4280
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/slug4280 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [==============================================================] 100.00% 6562/s 15s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      6609.73    1508.34   13145.76
  Latency       18.92ms     2.34ms    74.58ms
  Latency Distribution
     50%    18.83ms
     75%    20.19ms
     90%    21.80ms
     95%    23.10ms
     99%    26.54ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     1.80MB/s
Benchmark completed successfully.
Analyzing resource usage...
Timestamp       CPU(%)  Memory(MiB)
1742732843      0.02    44.71
1742732845      0.02    44.71
1742732847      85.34   69.55
1742732849      83.5    69.93
1742732851      84.26   69.97
1742732853      83.64   70.01
1742732855      84.23   70.04
1742732857      86.41   69.17
1742732859      85.77   69.2
1742732861      59.67   68.55

**** Resource Usage Statistics ****
  Measurements: 10
  Average CPU Usage: 65.29%
  Average Memory Usage: 64.58 MiB
  Peak CPU Usage: 86.41%
  Peak Memory Usage: 70.04 MiB
Cleanup completed. Resource usage data saved in resource_usage.txt
```
