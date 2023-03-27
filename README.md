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

## Dokku deployment
```bash
 bundle exec rails db:migrate
```

## Production link
https://url-shortener.sjdonado.de
