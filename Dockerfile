# ================= 第一阶段：下载与解压环境 =================
FROM alpine:latest AS fetcher

RUN apk --no-cache add curl tar

WORKDIR /tmp

# 动态下载最新的二进制
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

# ================= 第二阶段：纯净的运行时环境 =================
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata aria2

# 回归官方默认工作目录
WORKDIR /opt/openlist

# 从第一阶段复制二进制
COPY --from=fetcher /tmp/openlist /opt/openlist/openlist

# 在当前目录下创建独立的 data 和 downloads 目录，方便统一挂载
RUN mkdir -p /opt/openlist/data /opt/openlist/downloads && \
    chmod 777 /opt/openlist/downloads
RUN mkdir -p /opt/openlist/data/temp/aria2 && \
    chmod 777 /opt/openlist/data/temp/aria2
    
EXPOSE 5244

# 启动命令：
CMD ["sh", "-c", "aria2c --enable-rpc --rpc-listen-all=true --rpc-allow-origin-all=true --rpc-secret=123 --dir=/opt/openlist/downloads --daemon=true && ./openlist server --no-prefix --data /opt/openlist/data"]
