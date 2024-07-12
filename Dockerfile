FROM alpine:edge AS build

ENV ENV=production
WORKDIR /usr/src/app

RUN apk update && apk add --no-cache \
    crystal \
    shards \
    yaml-dev \
    sqlite-dev \
    openssl-dev

COPY . .

RUN shards install
RUN shards build --release --no-debug

FROM alpine:edge AS runtime

ENV ENV=production
WORKDIR /usr/src/app

RUN apk add --no-cache \
    gc \
    pcre2 \
    libevent \
    yaml \
    sqlite-libs \
    openssl

RUN mkdir -p sqlite

COPY --from=build /usr/src/app/db db
COPY --from=build /usr/src/app/data data
COPY --from=build /usr/src/app/bin /usr/local/bin

EXPOSE 4000/tcp
CMD ["bit"]
