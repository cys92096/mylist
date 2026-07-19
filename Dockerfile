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

# ================= 第二阶段：纯净的运行时环境（包含 Aria2） =================
FROM alpine:latest

# 安装基础证书、时区以及 aria2 离线下载工具
RUN apk --no-cache add ca-certificates tzdata aria2

WORKDIR /opt/openlist

# 从第一阶段仅仅把解压好的二进制文件复制过来
COPY --from=fetcher /tmp/openlist /opt/openlist/openlist

# 提前在持久化目录内创建下载子文件夹（Hugging Face 挂载 /data 目录）
# 确保权限开放，防止 aria2 写入因权限不足失败
RUN mkdir -p /data/downloads && chmod 777 /data/downloads

# 暴露 OpenList 网页端口
EXPOSE 5244

# 启动命令：使用 sh -c 先后台拉起 aria2c，再前台拉起 openlist
# 注意：请将 my_aria2_secret_token 换成你自己的专属复杂密码！
CMD ["sh", "-c", "aria2c --enable-rpc --rpc-listen-all=true --rpc-allow-origin-all=true --rpc-secret=123 --dir=/data/downloads --daemon=true && ./openlist server --no-prefix --data /data"]
