FROM dart:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.yaml
COPY packages/darttu_shared/pubspec.yaml packages/darttu_shared/pubspec.yaml
COPY packages/darttu_client/pubspec.yaml packages/darttu_client/pubspec.yaml
COPY packages/darttu_server/pubspec.yaml packages/darttu_server/pubspec.yaml

RUN dart pub get

COPY . .

RUN dart pub get
RUN mkdir -p /app/bin
RUN dart compile exe packages/darttu_server/bin/darttu_server.dart -o /app/bin/darttu_server

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/bin/darttu_server /app/darttu_server

RUN mkdir -p /data

ENV PORT=8080
ENV DARTTU_DB_PATH=/data/darttu_server.sqlite

EXPOSE 8080

CMD ["/bin/sh", "-c", "/app/darttu_server ${PORT} ${DARTTU_DB_PATH}"]
