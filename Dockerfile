FROM alpine:edge as base
WORKDIR /usr/src/app

RUN apk add crystal shards sqlite-dev openssl-dev

FROM base AS build
ENV ENV=production
COPY . . 

RUN shards install
RUN shards build --progress

FROM base AS release
RUN mkdir -p /usr/src/app/sqlite
COPY --from=build /usr/src/app/db db
COPY --from=build /usr/src/app/bin /usr/local/bin

EXPOSE 4000/tcp
CMD ["url-shortener"]
