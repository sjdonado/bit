# URL shortener

## How to run

### Development
- Run migrations
```bash
docker-compose up -d db
docker-compose run --rm app bundle exec rails db:migrate
```
- Run
```bash
docker-compose up
```

### Testing
```bash
docker-compose run --rm app bundle exec rails test
```

### Rubocop
```bash
docker-compose run --rm app bundle exec rubocop 
```

## Results

- Testing
```bash
Finished in 2.326313s, 10.3168 runs/s, 10.7466 assertions/s.
24 runs, 25 assertions, 0 failures, 0 errors, 0 skips
Coverage report generated for Minitest to /usr/src/app/coverage. 79 / 79 LOC (100.0%) covered.

COVERAGE: 100.00% -- 79/79 lines in 11 files
BRANCH COVERAGE: 100.00% -- 22/22 branches in 11 branches

+----------+-------------------------------------------+-------+--------+---------+-----------------+----------+-----------------+------------------+
| coverage | file                                      | lines | missed | missing | branch coverage | branches | branches missed | branches missing |
+----------+-------------------------------------------+-------+--------+---------+-----------------+----------+-----------------+------------------+
| 100.00%  | app/controllers/application_controller.rb | 2     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/controllers/links_controller.rb       | 22    | 0      |         | 100.00%         | 8        | 0               |                  |
| 100.00%  | app/controllers/sessions_controller.rb    | 14    | 0      |         | 100.00%         | 4        | 0               |                  |
| 100.00%  | app/controllers/users_controller.rb       | 12    | 0      |         | 100.00%         | 4        | 0               |                  |
| 100.00%  | app/helpers/application_helper.rb         | 1     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/helpers/links_helper.rb               | 1     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/helpers/sessions_helper.rb            | 7     | 0      |         | 100.00%         | 2        | 0               |                  |
| 100.00%  | app/helpers/users_helper.rb               | 1     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/models/application_record.rb          | 2     | 0      |         | 100.00%         | 0        | 0               |                  |
| 100.00%  | app/models/link.rb                        | 13    | 0      |         | 100.00%         | 4        | 0               |                  |
| 100.00%  | app/models/user.rb                        | 4     | 0      |         | 100.00%         | 0        | 0               |                  |
+----------+-------------------------------------------+-------+--------+---------+-----------------+----------+-----------------+------------------+
```

- Rubocop
```bash
Inspecting 58 files
..........................................................

58 files inspected, no offenses detected
```

- Production link
https://s-shortener.herokuapp.com/

## TODO
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
- [x] Setup Redis for production cache_store
- [x] Deployment CI