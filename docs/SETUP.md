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

RAM: 1GiB
CPU: Apple M3 Pro

**Summary**
- Reqs/sec (average central tendency): (1328.47 + 1357.19 + 1407.03) / 3 + (1785.03 + 1789.06 + 1778.84) / 3 = 3148.54 reqs/sec
- Latency (average central tendency): (76.19 + 74.68 + 71.85) / 3 - (29.43 + 14.50 + 9.42) / 3 = 56.4ms
- Latency (for conservative capacity planning): (76.19 + 74.68 + 71.85) / 3 + (29.43 + 14.50 + 9.42) / 3 = 89.63ms
- Best single run: 18041.44 reqs/sec

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
Selected link for benchmarking: http://localhost:4000/slug187082
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/slug187082 with 100000 request(s) using 100 connection(s)
 100000 / 100000 [==============================================================] 100.00% 12180/s 8s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec     12335.45    3288.95   20393.16
  Latency        8.11ms     1.89ms    35.42ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 0, 4xx - 0, 5xx - 100000
    others - 0
  Throughput:     2.93MB/s
Benchmark completed successfully.
Analyzing resource usage...
**** Resource Usage Statistics ****
  Measurements: 5
  Average CPU Usage: 39.5%
  Average Memory Usage: 35.25 MiB
  Peak CPU Usage: 82.25%
  Peak Memory Usage: 37.45 MiB
Cleanup completed. Resource usage data saved in resource_usage.txt
```
