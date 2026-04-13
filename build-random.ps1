# 获取当前 Git commit 的短哈希
try {
    $commitHash = git rev-parse --short HEAD
    $randomTag = "git-$commitHash"
    Write-Host "📌 Git Commit: $commitHash" -ForegroundColor Gray
} catch {
    # 如果不在 Git 仓库中，使用时间戳作为备选
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $randomTag = "build-$timestamp"
    Write-Host "⚠️  未检测到 Git 仓库，使用时间戳标签" -ForegroundColor Yellow
}

Write-Host "🔨 开始构建 Docker 镜像..." -ForegroundColor Green
Write-Host "🏷️  使用标签: $randomTag" -ForegroundColor Cyan

# 构建镜像
docker compose build --build-arg BUILD_HASH=$commitHash

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 构建成功!" -ForegroundColor Green
    Write-Host "🏷️  镜像名称: open-webui:$randomTag" -ForegroundColor Yellow
    
    # 同时标记为 latest
    docker tag open-webui:$randomTag open-webui:latest
    Write-Host "📝 已同时标记为 latest" -ForegroundColor Cyan
    
    # 显示镜像信息
    Write-Host "`n📊 镜像信息:" -ForegroundColor Green
    docker images open-webui:$randomTag
    
    # 显示最近的几个镜像
    Write-Host "`n📦 所有 open-webui 镜像:" -ForegroundColor Green
    docker images open-webui --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
} else {
    Write-Host "❌ 构建失败!" -ForegroundColor Red
    exit 1
}
