FROM alpine:edge AS build

ENV ENV=production
WORKDIR /usr/src/app

RUN apk add --no-cache \
    crystal \
    shards \
    openssl-dev \
    yaml-dev \
    sqlite-dev \
    libevent-dev \
    tzdata

COPY . .

RUN shards install --production
RUN shards build --release --no-debug --progress --stats

FROM alpine:latest AS runtime

ENV ENV=production
WORKDIR /usr/src/app

RUN apk add --no-cache \
    gc-dev \
    pcre2 \
    libevent \
    sqlite-libs \
    openssl \
    yaml \
    gmp \
    libgcc \
    tzdata

RUN mkdir -p sqlite

COPY --from=build /usr/src/app/db db
COPY --from=build /usr/src/app/data data
COPY --from=build /usr/src/app/bin /usr/local/bin

EXPOSE 4000/tcp
CMD ["bit"]
