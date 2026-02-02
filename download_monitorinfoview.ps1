# 定义下载和解压路径
$downloadUrl = "https://www.nirsoft.net/utils/monitorinfoview.zip"
$zipPath = "$env:TEMP\monitorinfoview.zip"
$extractPath = "$env:USERPROFILE\Tools\MonitorInfoView"
$timeoutSeconds = 30  # 下载超时时间（30秒）

# 创建目标目录（不存在则创建）
New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

# 初始化变量（用Script作用域确保事件能修改）
$script:downloadFinished = $false
$webClient = New-Object System.Net.WebClient
$progressEvent = $null
$completeEvent = $null

try {
    # 1. 注册下载进度事件
    $progressEvent = Register-ObjectEvent -InputObject $webClient `
        -EventName DownloadProgressChanged `
        -Action {
            $percent = $EventArgs.ProgressPercentage
            $bytesReceived = [math]::Round($EventArgs.BytesReceived / 1MB, 2)
            $totalBytes = [math]::Round($EventArgs.TotalBytesToReceive / 1MB, 2)
            Write-Host "`r下载进度: $percent% | 已下载: $bytesReceived MB / 总大小: $totalBytes MB" -NoNewline
        }

    # 2. 注册下载完成事件（明确修改Script级变量）
    $completeEvent = Register-ObjectEvent -InputObject $webClient `
        -EventName DownloadFileCompleted `
        -Action {
            $script:downloadFinished = $true
            Write-Host "`n✅ 下载完成！"
        }

    # 3. 开始异步下载
    Write-Host "📥 开始下载 MonitorInfoView（超时时间: $timeoutSeconds 秒）...`n"
    $webClient.DownloadFileAsync([Uri]$downloadUrl, $zipPath)
    
    # 4. 带超时的等待逻辑（解决卡顿核心）
    $waitCount = 0
    while (-not $script:downloadFinished -and $waitCount -lt $timeoutSeconds) {
        Start-Sleep -Seconds 1
        $waitCount++
        # 每5秒提示一次，避免看起来卡死
        if ($waitCount % 5 -eq 0 -and -not $script:downloadFinished) {
            Write-Host "`r⏳ 等待下载完成...（已等待 $waitCount 秒）" -NoNewline
        }
    }

    # 检查下载是否超时
    if (-not $script:downloadFinished) {
        throw "下载超时（超过 $timeoutSeconds 秒），请检查网络或下载链接！"
    }

    # 5. 验证压缩包是否存在（避免解压空文件）
    if (-not (Test-Path $zipPath)) {
        throw "下载的压缩包不存在！路径: $zipPath"
    }
    Write-Host "📂 验证压缩包成功，开始解压到: $extractPath"

    # 6. 解压（强制覆盖+显示进度）
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction Stop
    Write-Host "✅ 解压完成！"

    # 7. 验证可执行文件并运行
    $exePath = Join-Path -Path $extractPath -ChildPath "MonitorInfoView.exe"
    if (Test-Path $exePath) {
        Write-Host "🚀 正在启动 MonitorInfoView...`n"
        Start-Process -FilePath $exePath -NoNewWindow
    } else {
        throw "MonitorInfoView.exe 不存在！路径: $exePath"
    }

}
catch {
    Write-Host "`n❌ 操作失败：$($_.Exception.Message)" -ForegroundColor Red
    # 终止异步下载（避免后台残留）
    if ($webClient.IsBusy) {
        $webClient.CancelAsync()
    }
}
finally {
    # 强制清理所有资源（避免残留）
    if ($progressEvent) { Unregister-Event -Id $progressEvent.Id -ErrorAction SilentlyContinue }
    if ($completeEvent) { Unregister-Event -Id $completeEvent.Id -ErrorAction SilentlyContinue }
    $webClient.Dispose()
    # 清理临时变量
    Remove-Variable downloadFinished, progressEvent, completeEvent, waitCount -ErrorAction SilentlyContinue
    Write-Host "`n🔧 资源清理完成！"
}