# Stage 1: Compile pure Dart executable
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/tealkit_mcp.dart -o bin/tealkit_mcp

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

# Install ca-certificates for secure HTTPS requests (server & RAG crawler)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/tealkit_mcp /app/tealkit_mcp

# Entrypoint for MCP stdio protocol
ENTRYPOINT ["/app/tealkit_mcp"]
