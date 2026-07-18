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

# 只保留基础的时区和证书依赖
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /opt/openlist

# 从第一阶段仅仅把解压好的二进制文件“偷”过来
COPY --from=fetcher /tmp/openlist /opt/openlist/openlist

# 关键：提前创建独立的数据目录，方便宿主机安全挂载
RUN mkdir -p /opt/openlist/data

EXPOSE 5244

# 启动命令（将数据目录通过参数指向我们创建的 data 文件夹）
ENTRYPOINT ["./openlist"]
CMD ["server", "--no-prefix", "--data", "/data"]
