<#
.SYNOPSIS
一键优化GitHub连接并配置自定义hosts（包含屏蔽/内网域名）
.DESCRIPTION
自动以管理员权限运行，备份原有hosts，写入自定义配置，刷新DNS，优化Git参数
.NOTES
运行要求：PowerShell以管理员身份执行
#>

# --------------- 第一步：检查管理员权限 ---------------
# 检测当前PowerShell是否以管理员身份运行，无权限则提示并退出
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ 当前无管理员权限，无法修改系统hosts文件！" -ForegroundColor Red
    Write-Host "💡 请右键PowerShell → 选择「以管理员身份运行」后重新执行本脚本" -ForegroundColor Yellow
    Read-Host -Prompt "按任意键退出"
    exit 1
}

# --------------- 第二步：定义配置常量 ---------------
# Hosts文件路径
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
# Hosts备份路径（带时间戳，避免覆盖旧备份）
$backupPath = "$hostsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
# 要写入的自定义Hosts配置（包含你提供的所有项）
$customHosts = @"
# ==================== 自定义Hosts配置 Start ====================
# 本地回环绑定（屏蔽/本地调试）
127.0.0.1 powerservice.csii.com.cn
# GitHub优化配置（稳定IPv4解析）
140.82.114.3 github.com
185.199.108.133 assets-cdn.github.com
185.199.109.133 assets-cdn.github.com
185.199.110.133 assets-cdn.github.com
185.199.111.133 assets-cdn.github.com
# 屏蔽McAfee服务域名
0.0.0.1 mssplus.mcafee.com
# 内网域名绑定
192.168.3.106 windows10.microdone.cn
# ==================== 自定义Hosts配置 End ====================
"@

# --------------- 第三步：备份原有Hosts ---------------
try {
    Copy-Item -Path $hostsPath -Destination $backupPath -Force
    Write-Host "✅ 已备份原有hosts文件至：$backupPath" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Hosts备份失败（不影响配置写入）：$_" -ForegroundColor Yellow
}

# --------------- 第四步：写入自定义Hosts配置 ---------------
try {
    # 先检查配置是否已存在，避免重复写入
    $existingContent = Get-Content -Path $hostsPath -Raw -Encoding UTF8
    if ($existingContent -match "# ==================== 自定义Hosts配置 Start ====================") {
        Write-Host "ℹ️  检测到已存在相同的自定义Hosts配置，跳过重复写入" -ForegroundColor Cyan
    }
    else {
        # 追加配置到hosts文件末尾（UTF8编码，避免中文乱码）
        Add-Content -Path $hostsPath -Value $customHosts -Encoding UTF8
        Write-Host "✅ 自定义Hosts配置已成功写入" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Hosts配置写入失败：$_" -ForegroundColor Red
    Read-Host -Prompt "按任意键退出"
    exit 1
}

# --------------- 第五步：刷新DNS缓存 ---------------
try {
    ipconfig /flushdns | Out-Null
    Write-Host "✅ 本地DNS缓存已成功刷新" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  DNS缓存刷新失败：$_" -ForegroundColor Yellow
}

# --------------- 第六步：优化Git网络参数 ---------------
try {
    # 配置Git核心优化参数
    git config --global http.sslVerify false
    git config --global http.postBuffer 524288000
    git config --global http.maxRequestBuffer 100M
    git config --global core.compression 9
    git config --global ssh.keepalive true
    Write-Host "✅ Git网络优化参数已配置完成" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Git参数配置失败（请确认已安装Git）：$_" -ForegroundColor Yellow
}

# --------------- 执行完成提示 ---------------
Write-Host "`n🎉 所有配置已执行完成！" -ForegroundColor Green
Write-Host "📌 验证方法：" -ForegroundColor Cyan
Write-Host "  1. ping github.com → 应返回 140.82.114.3"
Write-Host "  2. ping mssplus.mcafee.com → 应提示「找不到主机」"
Write-Host "  3. git config --global --list → 可查看Git优化参数"
Read-Host -Prompt "`n按任意键退出"