#!/bin/bash

# 定义行分隔符，宽度84个字符
delimiter="===================================================================================="

# Set aliases
alias c='cp -f .bashrc ~/.bashrc'
alias v='vim ~/.bashrc'
alias s='source ~/.bashrc'
alias make='mingw32-make'

# Exported variablesssh -T git@github.com
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:"/c/Program Files/GitHub CLI/":/c/windows/system32:$PATH

# 当前开发环境路径
dev_env_dir="/d/github_ssh/MyDevEnv"
cd "$dev_env_dir"

# 帮助信息在此处扩展添加
helpList=("alias", "cmdhelp", "functions", "usual_utils", "usual_webs", "usual_winmtr")
source ./alias.sh
source ./cmdHelp.sh
source ./ssh-agent.sh

# 自定义函数help: 打印帮助信息
help() { # cmd help info
    printf "\t%s\n" "${helpList[@]}"
    grep '\t^[a-zA-Z0-9_]*() *{' ~/.bashrc
    printf "  -usual utils:\n"
    printf "\t%s\n" "${usual_utils[@]}"
    printf "  -usual webs:\n"
    printf "\tweb %s\n" "${usual_webs[@]}"
    printf "  -usual winmtr: # git clone git@github.com:leeter/WinMTR-refresh.git\n"
    printf "\twinmtr -i 1 -s 1024 -n %s &\n" "${usual_winmtr[@]}"
    printf "  -usual shell cmd:\n"
    printf "\t%s\n" "${usual_shell}"
    echo "$delimiter$delimiter"
    echo "开源 = Fork → 分支 → 编码→ PR → Review → 合并(ssh: git@github.com:yt-dlp/yt-dlp.git)"
    echo "$delimiter$delimiter"
}

usual_utils=("bash -n ~/.bashrc"
            "cygpath -w/-u"
	    "pacman -S/-R/-Syu"
	    "pip install/uninstall/install -U"
	    "declare -f; type -t;"
            "ssh-keygen -t ed25519 -C \"wang.shujian@foxmail.com\""
            "gpg --full-generate-key # 生成GPG密钥对（2.1.17之后的版本）"
            "gpg --list-secret-keys --keyid-format=long # 列出本地所有GPG密钥（查看刚生成的密钥）")
	    
usual_webs=("https://test.ustc.edu.cn"
	    "https://github.com"
	    "https://www.msys2.org"
	    "https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
	    "https://www.yyzlab.com.cn/aiEliteJobClass/1957271757362696205")

usual_winmtr=("github.com"
	      "www.yyzlab.com.cn"
	      "43.174.246.25 # 腾讯云新加坡 CDN 节点，面向普通用户的主站前端 / 静态资源 / 虚拟仿真平台入口"
	      "43.174.247.25 # 腾讯云新加坡 CDN 节点, CDN 集群的备用 / 分流节点"
	      "39.103.225.56 # 元宇宙实验中心-后台管理系统, 杭州阿里云内地服务器，归属华清远见")

usual_shell="
        运算符  语法            含义                              返回值(真 / 假)              典型应用场景
        -z      [[ -z "$var" ]] 检查变量值是否为空字符串 (长度 0) 空→真，非空→假               1. 校验环境变量是否未定义(如 if [ -z "$PID" ]) 2. 校验函数返回值是否为空
        -n      [[ -n "$var" ]] 检查变量值是否非空字符串(长度>0)  非空→真，空→假               1. 校验参数是否传入（如 if [ -n "$1" ]) 2. 校验提取的进程名是否有效
        -S      [[ -S "$file" ]]检查路径是否是套接字文件(socket)   是→真，否→假                 校验 ssh-agent 的套接字是否有效（if [ -S "$SOCK" ])
        -f      [[ -f "$file" ]]检查路径是否是普通文件(非目录)     是→真，否→假                 校验私钥 / 公钥文件是否存在(if [ -f "$SSH_PRIVATE_KEY" ])
        -d      [[ -d "$dir" ]] 检查路径是否是目录                是→真，否→假                 校验目录是否存在(如 if [ -d "$HOME/.ssh" ])
        -e      [[ -e "$path" ]]检查路径(文件 / 目录)              是否存在:存在→真，不存在→假  通用存在性校验(兼容文件 / 目录 / 套接字)"

# 自定义函数open: 命令行方式打开Windows指定路径	      
open() { # Open folder (null: current path ; $1: Unix path or Windows path)
    # 1. 转换当前路径为Windows格式（默认路径）
    local default_path=$(cygpath -w "$(pwd)")
    local path

    # 2. 判断是否传入参数：有则转换参数为Windows路径，无则用默认路径
    if [ -n "$1" ]; then
        path=$(cygpath -w "$1")
    else
        path=$default_path
    fi

    # 3. 打开路径（加引号兼容含空格的路径）
    explorer "$path"
}

# 自定义函数web: 打开指定网址
web() { # open the web page, usage: web https://github.com
    explorer "$1"
}

# ========== 仅Git Bash启动时执行，source时跳过 ==========
if [[ -n "$PS1" && "$0" =~ bash && -z "${BASH_SOURCE[1]}" ]]; then
    # 显示help信息
    echo "HelpInfo:"
    help
    echo "******************* Source the env and aliases are set done! ****************************"
else
    # 测试 SSH 连接 GitHub
    echo "$delimiter$delimiter"
    echo "ssh -T git@github.com:"
    ssh -T git@github.com
    echo "$delimiter$delimiter"

    # 通用工具信息函数
    print_tool_info() {
        local tool="$1"  # 函数内可用local

        # 检查工具是否存在
        if ! which "$tool" >/dev/null 2>&1; then
            echo "$delimiter"
            echo "⚠️ Tool '$tool' not found in PATH!"
            echo "$delimiter"
            return
        fi

        # 转换路径+查版本+输出分隔符（处理空格路径）
        cygpath -w "$(which "$tool")"
        "$tool" --version
	echo "$delimiter"
    }

    # 调用函数查询工具信息
    print_tool_info "git"
    print_tool_info "gcc"
    print_tool_info "python"
    print_tool_info "arm-none-eabi-gcc"

    # 先校验路径是否非空
    if [[ -z "$dev_env_dir" ]]; then
        echo "⚠️ dev_env_dir is empty!"
        echo "$delimiter"
    elif [ -d "$dev_env_dir" ]; then
        cd "$dev_env_dir" || {
            echo "⚠️ Failed to cd to $dev_env_dir!"
            echo "$delimiter"
            # cd失败时跳过后续git操作
            return
        }
        echo "📂 切换到目录：$dev_env_dir"
        ls *.md -1 2>/dev/null || echo "📄 No .md files found in $dev_env_dir"
        echo "$delimiter"
    else
        echo "$delimiter"
        echo "⚠️ Directory $dev_env_dir not found!"
        echo "$delimiter"
    fi
    
    # 检查 gh 登录状态
    gh auth status

    # 测试列出仓库
    gh repo list

    # 更新.bashrc并检查git状态
    echo "$delimiter"
    if [[ -d "$dev_env_dir/.git" ]]; then
        cp -f ~/.bashrc "$dev_env_dir/"
        git status
    else
        echo "⚠️ $dev_env_dir is not a Git repository!"
    fi
fi
# ========== 条件判断结束 ==========
