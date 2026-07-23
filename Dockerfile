FROM alpine:latest AS fetcher
RUN apk --no-cache add curl tar
WORKDIR /tmp
RUN echo "Downloading latest OpenList binary..." && \
    LATEST_URL=$(curl -s https://api.github.com/repos/OpenListTeam/OpenList/releases/latest | \
                 grep "browser_download_url.*linux-musl-amd64-lite.tar.gz" | \
                 cut -d '"' -f 4) && \
    curl -sL "$LATEST_URL" -o openlist.tar.gz && \
    tar -xzf openlist.tar.gz && \
    if [ -f openlist-linux-musl-amd64-lite ]; then \
        mv openlist-linux-musl-amd64-lite openlist; \
    fi && \
    chmod +x openlist

FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata aria2
WORKDIR /opt/openlist
COPY --from=fetcher /tmp/openlist /opt/openlist/openlist
RUN mkdir -p /opt/openlist/data /opt/openlist/downloads /opt/openlist/data/temp/aria2 && \
    chmod 777 /opt/openlist/downloads /opt/openlist/data/temp/aria2
EXPOSE 5244
CMD ["sh", "-c", "aria2c --enable-rpc --rpc-listen-all=true --rpc-allow-origin-all=true --rpc-secret=123 --dir=/opt/openlist/downloads --daemon=true && ./openlist server --no-prefix --data /opt/openlist/data"]
