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
Selected link for benchmarking: http://localhost:4000/slug2202
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/slug2202 for 59s using 30 connection(s)
[==============================================================================================] 59s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1321.38     427.84    2067.24
  Latency       33.19ms    51.13ms      2.00s
  Latency Distribution
     50%    30.01ms
     75%    34.38ms
     90%    40.59ms
     95%    48.35ms
     99%    65.21ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 39618, 4xx - 0, 5xx - 0
    others - 13712
  Errors:
    dial tcp [::1]:4000: connect: connection refused - 13712
  Throughput:   180.24KB/s
Benchmark completed successfully.
Analyzing resource usage...
**** Resource Usage Statistics ****
  Measurements: 21
  Average CPU Usage: 22.53%
  Average Memory Usage: 28.62 MiB
  Peak CPU Usage: 35.21%
  Peak Memory Usage: 62.14 MiB
Cleanup completed. Resource usage data saved in resource_usage.txt
```
