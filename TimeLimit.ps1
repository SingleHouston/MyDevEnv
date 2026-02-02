# 任务计划程序
# run taskschd.msc
# taskName: ComputerTimeLimit

# 配置参数
$maxMinutes = 100  # 最大使用时间（100分钟 = 1.5小时 + 10分钟浮动）
$warnMinutes = 80  # 警告时间（80分钟）
$logFile = "$env:APPDATA\ComputerUsage.log"

# 检查日志文件是否存在
if (-not (Test-Path $logFile)) {
    New-Item $logFile -Force | Out-Null
    Set-Content $logFile (Get-Date -Format "yyyy-MM-dd")
    Add-Content $logFile "0"
}

# 读取日志并检查日期
$logContent = Get-Content $logFile
$lastDate = $logContent[0]
$currentDate = Get-Date -Format "yyyy-MM-dd"

# 如果是新的一天，重置计时器
if ($lastDate -ne $currentDate) {
    Set-Content $logFile $currentDate
    Add-Content $logFile "0"
    $logContent = @($currentDate, "0")
}
else {
    $logContent = @($lastDate, $logContent[1])
}

$warned = $false

# 主计时循环
while ($true) {

    # 读取当前使用时间
    $minutesUsed = [int]$logContent[1]
    $minutesUsed += 1
    
    # 更新日志文件
    $logContent[1] = $minutesUsed.ToString()
    Set-Content $logFile $logContent
    
    # 检查时间限制
    if ($minutesUsed -ge $maxMinutes) {
        # 强制关机（100分钟时）
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("Computer time limit reached ($maxMinutes minutes). Shutting down in 60 seconds!", 60, "Time Limit", 0x0 + 0x30)
        Start-Sleep -Seconds 60
        Stop-Computer -Force
        exit
    }
	
	if(-not $warned) {
		if ($minutesUsed -ge $warnMinutes) {
			# 警告提示（80分钟时）
			$remaining = $maxMinutes - $minutesUsed
			$wshell = New-Object -ComObject Wscript.Shell
			$wshell.Popup("WARNING: You have used $minutesUsed minutes.`nTime remaining: $remaining minutes", 10, "Time Warning", 0x0 + 0x30)
			$warned = $true
		}
	}
    
    # 每分钟检查一次
    Start-Sleep -Seconds 60
}