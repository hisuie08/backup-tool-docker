FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    rsync cron bash && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY backup.sh /app/backup.sh
COPY entrypoint.sh /app/entrypoint.sh
COPY .env /app/.env

RUN chmod +x /app/backup.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
