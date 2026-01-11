FROM swift:6.0-jammy

RUN apt update && apt install -y \
    libssl3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Package.* ./
RUN swift package resolve

COPY Sources ./Sources
RUN swift build -c release

EXPOSE 8080

CMD ["swift", "run", "--configuration", "release"]