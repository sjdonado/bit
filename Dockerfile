FROM debian:bookworm-slim AS build

ARG TARGETARCH
ENV ENV=production
WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packagecloud.io/84codes/crystal/gpgkey | gpg --dearmor > /etc/apt/trusted.gpg.d/84codes_crystal.gpg \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/84codes_crystal.gpg] https://packagecloud.io/84codes/crystal/debian/ bookworm main" > /etc/apt/sources.list.d/84codes_crystal.list

RUN apt-get update && apt-get install -y \
    crystal \
    libssl-dev \
    libyaml-dev \
    libsqlite3-dev \
    libevent-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN shards install --production
RUN shards build --release --no-debug --progress --stats

FROM debian:bookworm-slim AS runtime

ENV ENV=production
WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    libssl3 \
    libyaml-0-2 \
    libsqlite3-0 \
    libevent-2.1-7 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p sqlite

COPY --from=build /usr/src/app/db db
COPY --from=build /usr/src/app/data data
COPY --from=build /usr/src/app/bin /usr/local/bin

EXPOSE 4000/tcp
CMD ["bit"]
