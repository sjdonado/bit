# URL shortener

<img width="1200" alt="image" src="https://user-images.githubusercontent.com/27580836/227800665-4ff7e2ae-8189-4593-8961-496b7c9ac861.png">

# Features
- [x] Create link model (make sure to create a index for the slug and click counter)
- [x] Generate unique slug
- [x] Link unit tests
- [x] Stimulus setup
- [x] Link controller (handle redirection)
- [x] Main page with input box
- [x] Create user model
- [x] User unit tests
- [x] Add userId key to link model
- [x] Login and logout (sessions)
- [x] User links view
- [x] Modals layout
- [x] Deployment CI

# How to run

## Development
- Run migrations
```bash
docker-compose up -d db
docker-compose run --rm app bundle exec rails db:migrate
```
- Run
```bash
docker-compose up
```

## Testing
```bash
docker-compose run --rm app bundle exec rails test
```

## Rubocop
```bash
docker-compose run --rm app bundle exec rubocop 
```

# Results

## Testing
```bash
Finished in 2.211344s, 9.9487 runs/s, 10.4009 assertions/s.
22 runs, 23 assertions, 0 failures, 0 errors, 0 skips
Coverage report generated for Minitest to /usr/src/app/coverage. 81 / 81 LOC (100.0%) covered.

COVERAGE: 100.00% -- 81/81 lines in 8 files
BRANCH COVERAGE: 100.00% -- 20/20 branches in 8 branches

+----------+-------------------------------------------+-------+--------+---------+-----------------+----------+-----------------+------------------+
| coverage | file                                      | lines | missed | missing | branch coverage | branches | branches missed | branches missing |
+----------+-------------------------------------------+-------+--------+---------+-----------------+----------+-----------------+------------------+
| 100.00%  | app/controllers/application_controller.rb | 3     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/controllers/links_controller.rb       | 23    | 0      |         | 100.00%         | 8        | 0               |                  |
| 100.00%  | app/controllers/sessions_controller.rb    | 17    | 0      |         | 100.00%         | 4        | 0               |                  |
| 100.00%  | app/controllers/users_controller.rb       | 16    | 0      |         | 100.00%         | 4        | 0               |                  |
| 100.00%  | app/helpers/sessions_helper.rb            | 3     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/models/application_record.rb          | 2     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/models/link.rb                        | 13    | 0      |         | 100.00%         | 4        | 0               |                  |
| 100.00%  | app/models/user.rb                        | 4     | 0      |         | 100.00%         | 0        | 0               |                  |
+----------+-------------------------------------------+-------+--------+---------+-----------------+----------+-----------------+------------------+
```

## Rubocop
```bash
Inspecting 43 files
...........................................

43 files inspected, no offenses detected
```

- Dokku deployment
```bash
 bundle exec rails assets:precompile
 bundle exec rails db:migrate
```

- Production link
https://url-shortener.sjdonado.de
