FROM alpine:edge as base
WORKDIR /usr/src/app

RUN apk add crystal shards sqlite-dev openssl-dev

FROM base AS build
ENV ENV=production
COPY . . 

RUN shards install
RUN shards build --progress

FROM base AS release
COPY --from=build /usr/src/app/bin/migrate .
COPY --from=build /usr/src/app/bin/url-shortener .
COPY --from=build /usr/src/app/bin/cli .

EXPOSE 4000/tcp
CMD ["./url-shortener"]
