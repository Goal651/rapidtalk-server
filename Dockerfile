FROM swift:6.0-jammy AS build

WORKDIR /build

# Copy package files first (cache)
COPY Package.* ./
RUN swift package resolve

# Copy source
COPY Sources ./Sources

# Build release
RUN swift build -c release

# ---- Runtime image ----
FROM swift:6.0-jammy-slim

RUN apt update && apt install -y \
    libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /build/.build/release/App /app/App

EXPOSE 8080
CMD ["./App", "serve", "--hostname", "0.0.0.0", "--port", "8080"]
