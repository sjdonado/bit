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

# Optional: Generate an api key
# docker exec -it bit cli --create-user=Admin
```

### Self-Hosted with Dokku

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

# Optional: Generate an api key
# dokku run bit cli --create-user=Admin
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

CPU: Apple M3 Pro

```
> colima start --cpu 1 --memory 1
INFO[0000] starting colima
INFO[0000] runtime: docker
INFO[0001] starting ...                                  context=vm
INFO[0076] provisioning ...                              context=docker
INFO[0077] starting ...                                  context=docker
INFO[0077] done

> ./benchmark.sh
Setting up...
[+] Running 3/3
 ✔ Network bit_default       Created                                                           0.0s
 ✔ Volume "bit_sqlite_data"  Created                                                           0.0s
 ✔ Container bit             Started                                                           0.1s
Captured API Key: Hs35FsYvUqF0dGf1IgkExA
Waiting for the application to be ready...
HTTP/1.1 200 OK
Connection: keep-alive
Content-Type: application/json
Date: Mon, 17 Mar 2025 08:40:58 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept, Origin, X-Api-Key
Content-Length: 13

Starting resource usage monitoring...
Creating 10000 short links with 100 concurrent requests...
Link creation complete: 10000 links created using httpbin's anything endpoint.
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/DYr5dA
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/DYr5dA with 100000 request(s) using 100 connection(s)
 100000 / 100000 [=================================================================================================================================================================] 100.00% 1424/s 1m10s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1443.96    1831.82   25297.17
  Latency       70.19ms     5.30ms   105.83ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   612.06KB/s
Benchmark completed.
Analyzing resource usage...
**** Results ****
Average CPU Usage: 39.47%
Average Memory Usage: 37.02 MiB
./benchmark.sh: line 135: 44732 Terminated: 15          monitor_resource_usage
[+] Running 2/2
 ✔ Container bit        Removed                                                                                                                                                                    10.1s
 ✔ Network bit_default  Removed                                                                                                                                                                     0.0s
```
