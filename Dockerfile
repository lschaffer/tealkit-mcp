# Stage 1: Compile pure Dart executable
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN mkdir -p /app/build && dart build cli --output /app/build

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

# Install ca-certificates for secure HTTPS requests (server & RAG crawler)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/bundle /app/bundle

ENV LD_LIBRARY_PATH=/app/bundle/lib

# Entrypoint for MCP stdio protocol
ENTRYPOINT ["/app/bundle/bin/tealkit_mcp"]
