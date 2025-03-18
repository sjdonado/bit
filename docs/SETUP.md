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
- Requests/secs average central tendency: (1328.47 + 1357.19 + 1407.03) / 3 + (1785.03 + 1789.06 + 1778.84) / 3 = 3148.54 reqs/sec
- Latency average central tendency: (76.19 + 74.68 + 71.85) / 3 - (29.43 + 14.50 + 9.42) / 3 = 56.4ms
- Latency for conservative capacity planning: (76.19 + 74.68 + 71.85) / 3 + (29.43 + 14.50 + 9.42) / 3 = 89.63ms
- Best Single Run: 18041.44 reqs/sec

```
~/p/bit> colima start --cpu 1 --memory 1
INFO[0000] starting colima
INFO[0000] runtime: docker
INFO[0001] starting ...                                  context=vm
INFO[0076] provisioning ...                              context=docker
INFO[0077] starting ...                                  context=docker
INFO[0077] done
~/p/bit> ./benchmark.sh
Setting up...
[+] Running 3/3
 ✔ Network bit_default       Created                                                           0.0s
 ✔ Volume "bit_sqlite_data"  Created                                                           0.0s
 ✔ Container bit             Started                                                           0.1s
Captured API Key: xFWMNJndUzuAC5sSRqgbSA
Waiting for the application to be ready...
HTTP/1.1 200 OK
Connection: keep-alive
Content-Type: application/json
Date: Tue, 18 Mar 2025 10:04:32 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept, Origin, X-Api-Key
Content-Length: 13

Starting resource usage monitoring...
Creating 10000 short links with 100 concurrent requests...
Link creation complete: 10000 links created using httpbin's anything endpoint.
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/4NRtcA
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/4NRtcA with 100000 request(s) using 100 connection(s)
 100000 / 100000 [============================================================] 100.00% 1308/s 1m16s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1328.47    1785.03   10390.15
  Latency       76.19ms    29.43ms   702.17ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   563.57KB/s
Benchmark completed.
Analyzing resource usage...
**** Results ****
Average CPU Usage: 37.02%
Average Memory Usage: 31.78 MiB
./benchmark.sh: line 135: 44688 Terminated: 15          monitor_resource_usage
[+] Running 2/2
 ✔ Container bit        Removed                                                               10.1s
 ✔ Network bit_default  Removed                                                                0.0s
~/p/bit> ./benchmark.sh
Setting up...
[+] Running 2/2
 ✔ Network bit_default  Created                                                                0.0s
 ✔ Container bit        Started                                                                0.1s
Captured API Key: zmEqrjCMbOGzdOXoCZPPsw
Waiting for the application to be ready...
HTTP/1.1 200 OK
Connection: keep-alive
Content-Type: application/json
Date: Tue, 18 Mar 2025 10:07:11 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept, Origin, X-Api-Key
Content-Length: 13

Starting resource usage monitoring...
Creating 10000 short links with 100 concurrent requests...
Link creation complete: 10000 links created using httpbin's anything endpoint.
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/kai6VA
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/kai6VA with 100000 request(s) using 100 connection(s)
 100000 / 100000 [============================================================] 100.00% 1336/s 1m14s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1357.19    1789.06   18041.44
  Latency       74.68ms    14.50ms   304.69ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   575.03KB/s
Benchmark completed.
Analyzing resource usage...
**** Results ****
Average CPU Usage: 38.00%
Average Memory Usage: 30.75 MiB
./benchmark.sh: line 135: 64339 Terminated: 15          monitor_resource_usage
[+] Running 2/2
 ✔ Container bit        Removed                                                               10.1s
 ✔ Network bit_default  Removed                                                                0.0s
~/p/bit> ./benchmark.sh
Setting up...
[+] Running 2/2
 ✔ Network bit_default  Created                                                                0.0s
 ✔ Container bit        Started                                                                0.1s
Captured API Key: fObPw7vIDCFBaxr8e9bI8g
Waiting for the application to be ready...
HTTP/1.1 200 OK
Connection: keep-alive
Content-Type: application/json
Date: Tue, 18 Mar 2025 10:08:57 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept, Origin, X-Api-Key
Content-Length: 13

Starting resource usage monitoring...
Creating 10000 short links with 100 concurrent requests...
Link creation complete: 10000 links created using httpbin's anything endpoint.
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/oxmHow
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/oxmHow with 100000 request(s) using 100 connection(s)
 100000 / 100000 [============================================================] 100.00% 1388/s 1m12s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec      1407.03    1778.84    5866.74
  Latency       71.85ms     9.42ms   175.45ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 100000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   597.97KB/s
Benchmark completed.
Analyzing resource usage...
**** Results ****
Average CPU Usage: 38.49%
Average Memory Usage: 36.48 MiB
./benchmark.sh: line 135: 79562 Terminated: 15          monitor_resource_usage
[+] Running 2/2
 ✔ Container bit        Removed                                                               10.1s
 ✔ Network bit_default  Removed                                                                0.0s
```
