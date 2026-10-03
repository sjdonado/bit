# AGENTS.md

bit is a self-hosted URL shortener: Crystal, Kemal, SQLite. `docs/openapi.yaml` is the API contract. `docs/SETUP.md` covers deployment and the benchmark.

## Map

- `bit.cr`: entry point. `app/routes.cr`: routes and the JSON `error` handlers.
- `app/controllers/`: `link.cr` (API), `click.cr` (redirect with async click tracking via `spawn`), `ping.cr`.
- `app/middlewares/`: `auth.cr` (`X-Api-Key` on every path except `/api/ping` and `/:slug`), `cors.cr`.
- `app/lib/`: `database.cr` (Crecto repo, runs migrations at boot), `migrator.cr`, `errors.cr`, `ua_parser.cr` and `ip_lookup.cr` (bounded caches).
- `app/services/`: `slug.cr`, `cli.cr` (user management, admin bootstrap from `ADMIN_NAME` and `ADMIN_API_KEY`). `app/config/env.cr`: environment defaults.
- `db/migrations/*.sql`: micrate-format files. `app/lib/migrator.cr` applies them at boot and keeps state in `micrate_db_version`.
- `data/`: user-agent regexes and the GeoLite2 database, refreshed by `.github/workflows/update-parsers.yml`.
- `scripts/cli.cr` and `scripts/benchmark.cr`. `spec/` runs in-process; `e2e/` starts `./bin/bit` as a real process.

## Constraints that are easy to miss

- `ENV` at compile time decides whether dotenv loads. Build the production binary with `ENV=production`. Any other build loads `.env.<ENV>` at runtime (default `.env.development`), and that file must exist.
- Migrations: `bit.cr` and every `cli` command except `--migrate-down` apply pending `-- +micrate Up` sections first. `cli --migrate-down` runs the `-- +micrate Down` section of the newest applied version and refuses an empty one (`20250319192003` is irreversible). The current image re-applies a rolled-back file on its next start, so a rollback only sticks when an older image is deployed next. A statement ends at a line ending with `;`, and any other `-- +micrate` directive raises. Each file runs in `BEGIN IMMEDIATE` with foreign keys off, so a `DROP TABLE` on a parent table does not cascade, and it fails if it adds a foreign key violation. Orphan rows from before foreign keys were enforced are tolerated, except that `20250319192003` cannot convert orphan links or clicks. A failing migration stops the app at boot.
- `App::Lib::Database::URL` appends `journal_mode=WAL`, `synchronous=NORMAL`, `foreign_keys=true`, and `busy_timeout=100` to `DATABASE_URL`; the app, the migrator, and the CLI all connect with it, and crystal-sqlite3 runs them as PRAGMAs on every connection. A key already present in `DATABASE_URL` wins, because crystal-sqlite3 reads the first value. WAL mode is what makes the redirect path fast. Foreign keys enforce the `ON DELETE CASCADE` rules. SQLite's busy wait blocks the single-threaded scheduler, so the timeout stays short.
- Kemal 1.14 discards a response body written before an error. Raise an `App::*Exception` from `app/lib/errors.cr`; do not print a body and then raise.
- Every API error is JSON. Auth runs before routing, so an unmatched route returns 401 without a key and `404 {"error":"Resource not found"}` with one. A wrong method returns 405 with an `Allow` header.
- Updating a link's URL regenerates its slug; the old short URL stops working.
- CI (`.github/workflows/tests.yml`, pull requests only) runs `shards install`, the production build, `crystal spec`, and `crystal spec e2e`. Formatting is not enforced.

## Checks

Run from the repository root, cheapest first:

1. `shards install`
2. `ENV=production shards build --release --no-debug` (builds `bit`, `cli`, `benchmark` into `bin/`)
3. `ENV=test crystal spec`
4. `ENV=test crystal spec e2e` (needs the step 2 binary)
5. `docker build -t bit:local .` (add `--platform linux/amd64` to check the other published architecture)

## Manual verification

The specs cover most status codes in-process. The steps below check the published image over a real network, GeoIP, headers, load, and memory. Use them when a change touches a route, the Dockerfile, a dependency, or the redirect path.

The endpoint walkthrough repeats status codes the specs already assert, on purpose. The specs call the handler chain in memory through spec-kemal, with the development build, macOS SQLite, and no socket. The walkthrough sends the same requests to the production binary inside the Docker image, so it also catches what only exists there: the `alpine` runtime libraries, the GeoLite2 file and user-agent regexes packaged in the image, the compile-time `ENV=production` branch, the SQLite settings on a real file, and headers over HTTP. A status code that passes in the specs and fails in the walkthrough points at the image or the build, not the code.

### Run with Docker

```bash
docker build -t bit:local .
docker run -d --rm --name bit-local -p 4000:4000 \
  -e APP_URL=http://localhost:4000 -e ADMIN_NAME=Admin -e ADMIN_API_KEY=local-key bit:local
docker logs bit-local      # expect "New user created" and no errors
```

Stop it with `docker stop bit-local`. The database lives in the container and is removed with it, so restart it before repeating the walkthrough.

### Every endpoint, including edge cases

Run under bash against a fresh container. Each `c` line prints the status code, the expected code, and the URL. Read the two printed bodies by eye.

```bash
B=http://localhost:4000; K="X-Api-Key: local-key"; J="Content-Type: application/json"
c() { local want=$1; shift; printf '%s expect %s  %s\n' "$(curl -s -o /dev/null -w '%{http_code}' "$@")" "$want" "${*: -1}"; }
new() { curl -s -H "$K" -H "$J" -d "{\"url\":\"$1\"}" $B/api/links | sed -E 's/^\{"data":\{"id":([0-9]+).*/\1/'; }
slug() { curl -s -H "$K" $B/api/links/$1 | sed -E 's/.*"refer":"[^"]*\/([^"]+)".*/\1/'; }

c 200 $B/api/ping
c 200 -X OPTIONS $B/api/links                                 # CORS preflight needs no key
c 401 $B/api/links
c 401 -H "X-Api-Key: wrong" $B/api/links
c 401 $B/missing/path                                         # auth runs before routing
c 404 -H "$K" $B/missing/path
c 405 -X POST -H "$K" $B/api/ping                             # Allow: GET, HEAD

ID=$(new https://example.com); S=$(slug $ID)
c 200 -H "$K" -H "$J" -d '{"url":"https://example.com"}' $B/api/links   # duplicate returns the existing link
c 422 -H "$K" -H "$J" -d '{"url":"not a url"}' $B/api/links
c 400 -H "$K" -H "$J" -d '{}' $B/api/links
c 400 -H "$K" -H "$J" -d '{bad' $B/api/links
c 400 -H "$K" -H "$J" -d '[1]' $B/api/links
c 200 -H "$K" "$B/api/links?limit=1"
c 400 -H "$K" "$B/api/links?limit=0"
c 400 -H "$K" "$B/api/links?limit=1001"
c 400 -H "$K" "$B/api/links?cursor=0"
c 400 -H "$K" "$B/api/links?cursor=abc"
c 400 -H "$K" $B/api/links/not-a-number
c 404 -H "$K" $B/api/links/999999

c 301 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/17.0 Safari/605.1.15" -e https://referrer.example/x $B/$S
c 301 -H "User-Agent:" -H "Cf-Connecting-Ip: 8.8.8.8" "$B/$S?utm_source=newsletter"
sleep 1; curl -s -H "$K" $B/api/links/$ID/clicks; echo
# newest first: country "US", referer "newsletter", null user_agent; then browser "Safari", os "Mac OS X", referer "referrer.example"
curl -s -o /dev/null -D - -H "Cf-Connecting-Ip: 8.8.8.8" $B/$S | grep -iE 'location|cache-control|x-forwarded-for'
# expect Location: https://example.com, Cache-Control: private, no-store, X-Forwarded-For: 8.8.8.8

ID2=$(new https://example.net)
c 422 -X PUT -H "$K" -H "$J" -d '{"url":"https://example.net"}' $B/api/links/$ID   # URL taken by another link
c 200 -X PUT -H "$K" -H "$J" -d '{"url":"https://example.org"}' $B/api/links/$ID
S2=$(slug $ID)
c 404 $B/$S                                                   # old slug stops working
c 301 $B/$S2

O="X-Api-Key: $(docker exec bit-local cli --create-user=Other | sed -E 's/.*X-Api-Key: //')"
c 404 -H "$O" $B/api/links/$ID
c 404 -H "$O" $B/api/links/$ID/clicks
c 403 -X PUT -H "$O" -H "$J" -d '{"url":"https://other.example"}' $B/api/links/$ID
c 403 -X DELETE -H "$O" $B/api/links/$ID

c 204 -X DELETE -H "$K" $B/api/links/$ID
c 404 $B/$S2                                                  # redirect gone after delete
c 204 -X DELETE -H "$K" $B/api/links/$ID2
```

### Load, throughput, and memory

```bash
ENV=production shards build --release --no-debug
./bin/benchmark   # needs bombardier and sqlite3 (brew install bombardier sqlite3)
```

The benchmark seeds `sqlite/data.benchmark.db`, starts `./bin/bit` on port 4001, and sends 100,000 redirect requests over 125 connections with keep-alives off. It fails unless every click reaches SQLite, and prints requests per second, the latency distribution, and the average and peak CPU and memory of the app process. Tune it with `BENCHMARK_REQUESTS`, `BENCHMARK_CONNECTIONS`, and `BENCHMARK_DISABLE_KEEP_ALIVES=false`.

- Run it three times and use the median run. The first run after a build can be far slower.
- Compare against a build of `master` on the same machine in the same session, not only against the numbers in `docs/SETUP.md`.
- When the README or `docs/SETUP.md` numbers change, record the machine, OS, and Crystal version next to them.

Container footprint, with a fresh container:

```bash
docker stats --no-stream bit-local                  # idle memory
S=$(curl -s -H "X-Api-Key: local-key" -H "Content-Type: application/json" -d '{"url":"https://load.example"}' http://localhost:4000/api/links | sed -E 's/.*"refer":"[^"]*\/([^"]+)".*/\1/')
bombardier -c 125 -n 100000 --disableKeepAlives http://localhost:4000/$S   # expect only 3xx
docker stats --no-stream bit-local                  # memory under load
docker save bit:local | gzip | wc -c                # compressed size; README claims under 20 MiB
```

Docker Desktop adds a network layer, so container throughput is lower than the native benchmark and not comparable to it.
