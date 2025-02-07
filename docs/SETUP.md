## CLI

```
Usage: ./cli [options]
Options:
  --create-user=NAME  Create a new user with the given name
  --list-users        List all users
  --delete-user=USER_ID Delete a user by ID
```

## Run it anywhere

### docker-compose

```bash
docker-compose up

# Optional: Generate an api key
# docker-compose exec -it app cli --create-user=Admin
```

### Docker cli

```bash
docker run \
    --name bit \
    -p 4000:4000 \
    -e ENV="production" \
    -e DATABASE_URL="sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true" \
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

dokku config:set bit DATABASE_URL="sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true" APP_URL=https://bit.donado.co ADMIN_NAME=Admin ADMIN_API_KEY=$(openssl rand -base64 32)

dokku ports:add bit http:80:4000
dokku ports:add bit https:443:4000

# Optional: Generate an api key
# dokku run bit cli --create-user=Admin
```

## Benchmark

```
$ ./benchmark.sh
Setting up...
[+] Running 3/3
 ✔ Network bit_default       Created                                                                         0.0s
 ✔ Volume "bit_sqlite_data"  Created                                                                         0.0s
 ✔ Container bit             Started                                                                         0.1s
Captured API Key: aHOCnZSuo2kOHy2mDa-iOA
Waiting for the application to be ready...
HTTP/1.1 200 OK
Connection: keep-alive
Content-Type: application/json
Date: Sun, 27 Oct 2024 11:52:33 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept, Origin, X-Api-Key
Content-Length: 13

Starting resource usage monitoring...
Creating 10000 short links with 100 conrurrent requests...
Link creation complete: 10000 links created.
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/UaVZjA
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/oEKLAg with 10000 request(s) using 100 connection(s)
 10000 / 10000 [===============================================================================] 100.00% 830/s 12s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec       853.89    1625.49    8942.54
  Latency      118.48ms    11.52ms   142.58ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 10000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   360.02KB/s
Benchmark completed.
Analyzing resource usage...
**** Results ****
Average CPU Usage: 40.68%
Average Memory Usage: 28.62 MiB
./benchmark.sh: line 135: 61567 Terminated: 15          monitor_resource_usage
[+] Running 2/2
 ✔ Container bit        Removed                                                                                                                                                                                               10.1s
 ✔ Network bit_default  Removed  
```
