[![Docker Pulls](https://img.shields.io/docker/pulls/sjdonado/bit.svg)](https://hub.docker.com/repository/docker/sjdonado/bit)
[![Docker Stars](https://img.shields.io/docker/stars/sjdonado/bit.svg)](https://hub.docker.com/repository/docker/sjdonado/bit)
[![Docker Image Size](https://img.shields.io/docker/image-size/sjdonado/bit/latest)](https://hub.docker.com/repository/docker/sjdonado/bit)

# Benchmark

```shell
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
Creating 10000 short links with parallel requests...
Link creation complete: 10000 links created.
Fetching all created links from /api/links...
Selected link for benchmarking: http://localhost:4000/oEKLAg
Starting benchmark with Bombardier...
Bombarding http://localhost:4000/oEKLAg with 10000 request(s) using 100 connection(s)
 10000 / 10000 [===============================================================================] 100.00% 844/s 11s
Done!
Statistics        Avg      Stdev        Max
  Reqs/sec       857.65    1577.98    5255.85
  Latency      116.99ms    10.31ms   133.59ms
  HTTP codes:
    1xx - 0, 2xx - 0, 3xx - 10000, 4xx - 0, 5xx - 0
    others - 0
  Throughput:   362.05KB/s
Benchmark completed.
Analyzing resource usage...
**** Results ****
Average CPU Usage: 43.20%
Average Memory Usage: 25.52 MiB
```

# Self-hosted

## Run via docker-compose

```bash
docker-compose up

# Generate an api key
docker-compose exec -it app cli --create-user=Admin
```

## Run via docker cli

```bash
docker run \
    --name bit \
    -p 4000:4000 \
    -e ENV="production" \
    -e DATABASE_URL="sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true" \
    -e APP_URL="http://localhost:4000" \
    sjdonado/bit

docker exec -it bit cli --create-user=Admin
```

## Dokku

```dockerfile
FROM sjdonado/bit
```

```bash
dokku apps:create bit

dokku domains:set bit bit.donado.co
dokku letsencrypt:enable bit

dokku storage:ensure-directory bit-sqlite
dokku storage:mount bit /var/lib/dokku/data/storage/bit-sqlite:/usr/src/app/sqlite/

dokku config:set bit DATABASE_URL="sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true" APP_URL=https://bit.donado.co

dokku ports:add bit http:80:4000
dokku ports:add bit https:443:4000

dokku run bit cli --create-user=Admin
```

# Usage

## API Endpoints

1. **Ping the API**

   - Endpoint: `GET /api/ping`
   - Payload: None
   - Response Example
     ```json
     {
       "message": "pong"
     }
     ```

2. **Retrieve a link by its slug**

   - Endpoint: `GET /:slug`
   - Headers: `X-Api-Key`
   - Payload: None
   - Response Example
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://monocuco.donado.co",
         "clicks": [
           {
             "id": "730e2202-58f9-478c-a24c-f1c561df6716",
             "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0",
             "language": "en-US",
             "browser": "Firefox",
             "os": "Mac OS X",
             "source": "Unknown",
             "created_at": "2024-07-12T19:25:22Z"
           }
         ]
       }
     }
     ```

3. **Retrieve all links**

   - Endpoint: `GET /api/links`
   - Headers: `X-Api-Key`
   - Payload: None
   - Response Example
     ```json
     {
       "data": [
         {
           "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
           "refer": "http://localhost:4000/3wP4BQ",
           "origin": "https://monocuco.donado.co",
           "clicks": [
             {
               "id": "730e2202-58f9-478c-a24c-f1c561df6716",
               "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0",
               "language": "en-US",
               "browser": "Firefox",
               "os": "Mac OS X",
               "source": "Unknown",
               "created_at": "2024-07-12T19:25:22Z"
             }
           ]
         }
       ]
     }
     ```

4. **Retrieve a link by its ID**

   - Endpoint: `GET /api/links/:id`
   - Headers: `X-Api-Key`
   - Payload: None
   - Response Example
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://monocuco.donado.co",
         "clicks": [
           {
             "id": "730e2202-58f9-478c-a24c-f1c561df6716",
             "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:127.0) Gecko/20100101 Firefox/127.0",
             "language": "en-US",
             "browser": "Firefox",
             "os": "Mac OS X",
             "source": "Unknown",
             "created_at": "2024-07-12T19:25:22Z"
           }
         ]
       }
     }
     ```

5. **Create a new link**

   - Endpoint\*\*: `POST /api/links`
   - Payload:
     ```json
     {
       "url": "https://example.com"
     }
     ```
   - Headers: `X-Api-Key`
   - Response Example:
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://monocuco.donado.co/test",
         "clicks": []
       }
     }
     ```

6. **Update an existing link by its ID**

   - Endpoint: `PUT /api/links/:id`
   - Payload:
     ```json
     {
       "url": "https://newexample.com"
     }
     ```
   - Headers: `X-Api-Key`
   - Response Example:
     ```json
     {
       "data": {
         "id": "84f0c7a4-8c4e-4665-b676-cb9c5e40f1db",
         "refer": "http://localhost:4000/3wP4BQ",
         "origin": "https://newexample.com",
         "clicks": []
       }
     }
     ```

7. **Delete a link by its ID**

   - Endpoint: `DELETE /api/links/:id`
   - Payload: None
   - Headers: `X-Api-Key`
   - Response Example:
     ```json
     {
       "message": "Link deleted"
     }
     ```

## CLI

```
Usage: ./cli [options]
Options:
  --create-user=NAME  Create a new user with the given name
  --list-users        List all users
  --delete-user=USER_ID Delete a user by ID
```

# Development

## Installation

```bash
brew tap amberframework/micrate
brew install micrate
```

```bash
shards run bit
```

## Generate the `X-Api-Key`

```bash
shards run cli -- --create-user=Admin
```

## Run tests

```bash
ENV=test crystal spec
```

## Contributing

1. Fork it (<https://github.com/sjdonado/bit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
