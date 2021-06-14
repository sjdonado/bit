# URL shortener

## How to run

### Development
- Setup
```bash
docker-compose up -d
docker-compose run --rm app bundle exec rails db:migrate
docker-compose stop
```
- Run
```bash
docker-compose up
```

### Testing
- Run tests
```bash
docker-compose run --rm app bundle exec rails test
```

### Rubocop
```bash
docker-compose run --rm app rubocop 
```

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
- [ ] Modals layout
- [ ] Setup Redis for production cache_store 