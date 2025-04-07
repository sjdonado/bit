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
Selected link for benchmarking: http://localhost:4000/slug2576
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/slug2576 with 100000 request(s) using 125 connection(s)
 100000 / 100000 [===================================================================================================================================================================] 100.00% 7795/s 12s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      7900.70    7570.15   29263.59
  Latency       15.89ms    10.22ms    67.32ms
  Latency Distribution
     50%     4.82ms
     75%     9.24ms
     90%    51.61ms
     95%    52.74ms
     99%    55.07ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:     2.14MB/s
Benchmark completed successfully.
Analyzing resource usage...
Timestamp       CPU(%)  Memory(MiB)
1742763202      0.01    44.83
1742763204      0.01    44.78
1742763206      91.53   68.23
1742763208      92.03   68.17
1742763210      91.0    68.09
1742763212      92.73   68.38
1742763214      92.17   67.66
1742763216      91.1    67.69
1742763218      2.93    67.04

**** Resource Usage Statistics ****
  Measurements: 9
  Average CPU Usage: 61.5%
  Average Memory Usage: 62.76 MiB
  Peak CPU Usage: 92.73%
  Peak Memory Usage: 68.38 MiB
Cleanup completed. Resource usage data saved in resource_usage.txt
```
