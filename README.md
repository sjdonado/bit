# url-shortener
> Lightning fast, lightweight and minimal self-hosted url shortener

## Self-hosted

- Dokku
```dockerfile
FROM sjdonado/url-shortener
```

```bash
dokku apps:create url-shortener

dokku domains:set url-shortener bit.donado.co 
dokku letsencrypt:enable url-shortener

dokku storage:ensure-directory url-shortener-sqlite
dokku storage:mount url-shortener /var/lib/dokku/data/storage/url-shortener-sqlite:/usr/src/app/sqlite/

dokku config:set url-shortener DATABASE_URL="sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true" APP_URL=https://bit.donado.co

dokku ports:add url-shortener http:80:4000
dokku ports:add url-shortener https:443:4000

dokku run url-shortener migrate
dokku run url-shortener cli --create-user=Admin
```

- Run
```bash
docker run \
    --name url-shortener \
    -p 4000:4000 \
    -e ENV="production" \
    -e DATABASE_URL="sqlite3://./sqlite/data.db?journal_mode=wal&synchronous=normal&foreign_keys=true" \
    -e APP_URL="http://localhost:4000" \
    sjdonado/url-shortener

docker exec -it url-shortener migrate
docker exec -it url-shortener cli --create-user=Admin
```

## Usage

**REST API**

| Endpoint | HTTP Method | Description | Payload |
|----------|-------------|-------------|---------|
| `/api/ping` | GET | Ping the API to check if it's running | - |
| `/:slug` | GET | Retrieve a link by its slug | - |
| `/api/links` | GET | Retrieve all links | - |
| `/api/links` | POST | Create a new link | `{"url": "https://example.com"}` |
| `/api/links/:id` | PUT | Update an existing link by its ID | `{"url": "https://newexample.com"}` |
| `/api/links/:id` | DELETE | Delete a link by its ID | - |

**CLI**
```
Usage: ./cli [options]
Options:
  --create-user=NAME  Create a new user with the given name
  --list-users        List all users
  --delete-user=USER_ID Delete a user by ID
```

## Development

**Installation**

```bash
brew tap amberframework/micrate
brew install micrate
```

```bash
shards run migrate
shards run url-shortener
```

**Generate an API_KEY**

```bash
shards run cli -- --create-user=Admin
```

## Run tests
```bash
ENV=test crystal spec
```

## Contributing

1. Fork it (<https://github.com/sjdonado/url-shortener/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [sjdonado](https://github.com/sjdonado) - creator and maintainer
