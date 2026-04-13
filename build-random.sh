#!/bin/bash

# 获取当前 Git commit 的短哈希
if git rev-parse --git-dir > /dev/null 2>&1; then
    COMMIT_HASH=$(git rev-parse --short HEAD)
    RANDOM_TAG="git-${COMMIT_HASH}"
    echo "📌 Git Commit: $COMMIT_HASH"
else
    # 如果不在 Git 仓库中，使用时间戳作为备选
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    RANDOM_TAG="build-${TIMESTAMP}"
    echo "⚠️  未检测到 Git 仓库，使用时间戳标签"
fi

echo "🔨 开始构建 Docker 镜像..."
echo "🏷️  使用标签: $RANDOM_TAG"

# 构建镜像
docker compose build --build-arg BUILD_HASH=$COMMIT_HASH

if [ $? -eq 0 ]; then
    echo "✅ 构建成功!"
    echo "🏷️  镜像名称: open-webui:$RANDOM_TAG"
    
    # 同时标记为 latest
    docker tag open-webui:$RANDOM_TAG open-webui:latest
    echo "📝 已同时标记为 latest"
    
    # 显示镜像信息
    echo -e "\n📊 镜像信息:"
    docker images open-webui:$RANDOM_TAG
    
    # 显示最近的几个镜像
    echo -e "\n📦 所有 open-webui 镜像:"
    docker images open-webui --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
else
    echo "❌ 构建失败!"
    exit 1
fi
