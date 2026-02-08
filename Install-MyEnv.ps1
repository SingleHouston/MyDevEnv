<#
.SYNOPSIS
Windows嵌入式开发环境一键部署脚本（PowerShell 5.1完全兼容版）
.DESCRIPTION
彻底移除所有7+语法，仅用5.1原生语法，无任何解析报错
.AUTHOR
AI环境管家（适配嵌入式开发场景）
.PARAMETER ARM_GCC_Path
自定义ARM_GCC安装路径（默认：D:\Tools\ARM_GCC\bin）
.EXAMPLE
.\Install-MyEnv.ps1 -ARM_GCC_Path "E:\Dev\ARM_GCC\bin"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ARM_GCC_Path = "D:\Tools\ARM_GCC\bin"
)

# ===================== 初始化配置 =====================
$Blue = "Blue"
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"
$White = "White"
'''
    -ForegroundColor [<System.ConsoleColor>]
        Specifies the text color. There is no default. The acceptable values for this parameter are:

        - `Black`
        - `DarkBlue`
        - `DarkGreen`
        - `DarkCyan`
        - `DarkRed`
        - `DarkMagenta`
        - `DarkYellow`
        - `Gray`
        - `DarkGray`
        - `Blue`
        - `Green`
        - `Cyan`
        - `Red`
        - `Magenta`
        - `Yellow`
        - `White`
'''
# 强制解析~为实际路径（解决5.1路径解析bug）
$actualHome = [Environment]::GetFolderPath("MyDocuments").Replace("\Documents", "")
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "`n===== 环境部署初始化 =====`n" -ForegroundColor $Cyan
Write-Host "当前执行权限：$(if ($isAdmin) { "管理员" } else { "普通用户" })" -ForegroundColor $White
Write-Host "ARM_GCC_PATH默认配置：$ARM_GCC_Path`n" -ForegroundColor $White

# ===================== 步骤1：永久取消where别名 =====================
Write-Host "===== 步骤1：取消where别名（优先调用where.exe）=====`n" -ForegroundColor $Cyan
try {
    if (Test-Path Alias:where) {
        Remove-Item Alias:where -Force -ErrorAction Stop
        Write-Host "✅ 已成功取消where别名" -ForegroundColor $Green
    } else {
        Write-Host "ℹ️ where别名已取消，无需重复操作" -ForegroundColor $White
    }
} catch {
    Write-Host "❌ 取消where别名失败：$_" -ForegroundColor $Red
}

# ===================== 步骤2：配置PowerShell提示符（5.1极简兼容版） =====================
Write-Host "`n===== 步骤2：配置PowerShell个性化提示符 =====`n" -ForegroundColor $Cyan
try {
    # 硬编码PowerShell 5.1默认PROFILE路径（彻底避免路径解析问题）
    $profileDir = "$actualHome\Documents\WindowsPowerShell"
    $profilePath = "$profileDir\Microsoft.PowerShell_profile.ps1"

    # 创建目录（5.1原生md命令）
    if (-not (Test-Path $profileDir)) {
        md $profileDir -Force | Out-Null
        Write-Host "ℹ️ 已创建PROFILE目录：$profileDir" -ForegroundColor $White
    }

    # 提示符函数（纯5.1语法，无三元运算符、无复杂语法）
    $promptScript = @'
# 永久取消where别名（5.1兼容）
if (Test-Path Alias:where) {
    Remove-Item Alias:where -Force -ErrorAction SilentlyContinue
}

# 嵌入式开发个性化提示符（纯5.1语法）
function prompt {
    $maxFullPathLen = 30
    $maxLastDirLen = 30
    $fullPath = $PWD.Path
    $lastDir = [System.IO.Path]::GetFileName($fullPath)
    $showContent = ""

    # 规则1：完整路径≤30 → 显示完整路径
    if ($fullPath.Length -le $maxFullPathLen) {
        $showContent = $fullPath
    }
    # 规则2：完整路径>30 → 显示最后一级（超长则截断+...）
    else {
        if ([string]::IsNullOrEmpty($lastDir)) {
            $showContent = [System.IO.Path]::GetPathRoot($fullPath)
        } else {
            # 5.1不支持三元，改用if-else
            if ($lastDir.Length -gt $maxLastDirLen) {
                $showContent = $lastDir.Substring(0,27) + "..."
            } else {
                $showContent = $lastDir
            }
        }
    }

    # 拼接提示符（简洁无冗余）
    return "$ ...\" + $showContent + ">"
}
'@

    # 5.1原生写入方式（Set-Content，无-Path参数）
    $promptScript | Set-Content $profilePath -Encoding UTF8 -Force
    Write-Host "✅ 已将提示符配置写入：$profilePath" -ForegroundColor $Green

    # 手动加载配置
    . $profilePath
    Write-Host "✅ 提示符已生效：$(prompt)" -ForegroundColor $Green
} catch {
    Write-Host "❌ 配置提示符失败：$_" -ForegroundColor $Red
    Write-Host "ℹ️ 手动修复：新建$profilePath，粘贴上述promptScript内容" -ForegroundColor $White
}

# ===================== 步骤3：检测并配置工具链（移除三元运算符） =====================
Write-Host "`n===== 步骤3：检测并配置嵌入式工具链 =====`n" -ForegroundColor $Cyan
# 工具链检测函数（纯5.1语法）
function Test-Toolchain {
    param(
        [string]$ToolName
    )
    try {
        $toolPath = (Get-Command $ToolName -ErrorAction Stop).Source
        return $toolPath
    } catch {
        return $null
    }
}

# 检测GCC
$gccPath = Test-Toolchain -ToolName "gcc"
if ($gccPath) {
    $gccDir = Split-Path $gccPath -Parent
    Write-Host "ℹ️ 检测到GCC：$gccPath" -ForegroundColor $White
    if ($env:PATH -notlike "*$gccDir*") {
        # 5.1用if-else替代三元运算符
        if ($isAdmin) {
            $pathType = "Machine"
        } else {
            $pathType = "User"
        }
        [Environment]::SetEnvironmentVariable("PATH", "$([Environment]::GetEnvironmentVariable('PATH',$pathType));$gccDir", $pathType)
        $env:PATH += ";$gccDir"
        Write-Host "✅ 已添加GCC路径到$pathType级PATH" -ForegroundColor $Green
    } else {
        Write-Host "ℹ️ GCC路径已在PATH中" -ForegroundColor $White
    }
} else {
        Write-Host "⚠️ 未检测到GCC，建议安装MSYS2（https://www.msys2.org/）`nℹ️ 先更新包数据库（可选但推荐，避免包版本不匹配）pacman -Sy `nℹ️ 安装gcc核心包（自动确认安装，包含gcc、g++等编译器）pacman -S --noconfirm mingw-w64-x86_64-gcc" -ForegroundColor Yellow
}

# 检测ARM-GCC
$armGccPath = Test-Toolchain -ToolName "arm-none-eabi-gcc"
if ($armGccPath) {
    $armGccDir = Split-Path $armGccPath -Parent
    Write-Host "ℹ️ 检测到ARM-GCC：$armGccPath" -ForegroundColor $White
    if ($env:PATH -notlike "*$armGccDir*") {
        # 5.1用if-else替代三元运算符
        if ($isAdmin) {
            $pathType = "Machine"
        } else {
            $pathType = "User"
        }
        [Environment]::SetEnvironmentVariable("PATH", "$([Environment]::GetEnvironmentVariable('PATH',$pathType));$armGccDir", $pathType)
        $env:PATH += ";$armGccDir"
        Write-Host "✅ 已添加ARM-GCC路径到$pathType级PATH" -ForegroundColor $Green
    } else {
        Write-Host "ℹ️ ARM-GCC路径已在PATH中" -ForegroundColor $White
    }
} else {
    Write-Host "⚠️ 未检测到arm-none-eabi-gcc，请下载官方版本：" -ForegroundColor $Yellow
    Write-Host "   https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads" -ForegroundColor $Yellow
}

# ===================== 步骤4：配置ARM_GCC_PATH（纯5.1语法） =====================
Write-Host "`n===== 步骤4：配置ARM_GCC_PATH环境变量 =====`n" -ForegroundColor $Cyan
try {
    # 5.1用if-else替代三元运算符
    if ($isAdmin) {
        $pathType = "Machine"
    } else {
        $pathType = "User"
    }
    $existingARM_GCC = [Environment]::GetEnvironmentVariable("ARM_GCC_PATH", $pathType)

    if ($existingARM_GCC -eq $ARM_GCC_Path) {
        Write-Host "ℹ️ ARM_GCC_PATH已配置：$ARM_GCC_Path" -ForegroundColor $White
    } else {
        [Environment]::SetEnvironmentVariable("ARM_GCC_PATH", $ARM_GCC_Path, $pathType)
        # 强制刷新当前会话变量
        $env:ARM_GCC_PATH = $ARM_GCC_Path
        Write-Host "✅ 已配置ARM_GCC_PATH（$pathType级）：$ARM_GCC_Path" -ForegroundColor $Green
    }
} catch {
    Write-Host "❌ 配置ARM_GCC_PATH失败：$_" -ForegroundColor $Red
}

# ===================== 步骤5：部署验证（纯5.1语法，修复所有报错） =====================
Write-Host "`n===== 步骤5：部署结果验证 =====`n" -ForegroundColor $Cyan

# 1. 提示符验证
Write-Host "1. PowerShell提示符：" -ForegroundColor $Cyan
try {
    $currentPrompt = prompt
    Write-Host "   ✅ $currentPrompt" -ForegroundColor $Green
} catch {
    Write-Host "   ❌ 提示符验证失败：$_" -ForegroundColor $Red
}

# 2. where别名验证
Write-Host "2. where arm-none-eabi-gcc：" -ForegroundColor $Cyan
try {
    $whereRes = where arm-none-eabi-gcc 2>&1
    Write-Host "   ✅ $whereRes" -ForegroundColor $Green
} catch {
    Write-Host "   ⚠️ 未找到arm-none-eabi-gcc（可能未安装）" -ForegroundColor $Yellow
}

# 3. GCC版本验证
Write-Host "3. GCC版本：" -ForegroundColor $Cyan
try {
    $gccVer = (gcc --version 2>&1)[0]
    Write-Host "   ✅ $gccVer" -ForegroundColor $Green
} catch {
    Write-Host "   ⚠️ GCC未安装或路径未配置" -ForegroundColor $Yellow
}

# 4. ARM_GCC_PATH验证（纯5.1语法）
Write-Host "4. ARM_GCC_PATH环境变量：" -ForegroundColor $Cyan
try {
    # 5.1用if-else替代三元运算符
    if ($isAdmin) {
        $pathType = "Machine"
    } else {
        $pathType = "User"
    }
    $armGccVal = [Environment]::GetEnvironmentVariable("ARM_GCC_PATH", $pathType)
    Write-Host "   ✅ $armGccVal" -ForegroundColor $Green
} catch {
    Write-Host "   ❌ ARM_GCC_PATH为空或配置失败" -ForegroundColor $Red
}

# ===================== 部署完成总结 =====================
Write-Host "`n===== 环境部署完成 =====`n" -ForegroundColor $Cyan
Write-Host "📌 关键提示：" -ForegroundColor $Yellow
Write-Host "   1. 重启PowerShell后，所有配置永久生效"
Write-Host "   2. 若提示符未生效，手动执行：. `$PROFILE"
Write-Host "   3. 工具链未安装则按提示下载后重新执行脚本`n" -ForegroundColor $Yellow

# 脚本末尾添加：重置控制台所有颜色到系统默认
[Console]::ResetColor()