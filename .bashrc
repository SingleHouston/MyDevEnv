#!/bin/bash

# 定义行分隔符，宽度84个字符
delimiter="===================================================================================="

# 核心配置（根据实际情况修改）
AGENT_ENV_FILE="$HOME/.ssh/agent.env"   # 保存agent环境变量的文件
SSH_PRIVATE_KEY="$HOME/.ssh/id_ed25519"     # 私钥文件路径
KEY_EXPIRE_SECONDS=3600                 # 密钥超时时间（1小时）

# 函数1：验证ssh-agent环境是否有效（进程存活+通信正常）
validate_agent_env() {
    local env_pid env_sock
    
    # 从环境文件提取核心变量（过滤冗余行，清理格式）
    if [ -f "$AGENT_ENV_FILE" ]; then
        env_pid=$(grep -E '^SSH_AGENT_PID=' "$AGENT_ENV_FILE" | cut -d'=' -f2 | tr -d '; ' | xargs)
        env_sock=$(grep -E '^SSH_AUTH_SOCK=' "$AGENT_ENV_FILE" | cut -d'=' -f2 | tr -d '; ' | xargs)
    fi

    # 三重校验：PID存在 + 是ssh-agent进程 + 套接字有效
    if [ -n "$env_pid" ] && ps -p "$env_pid" -o comm= 2>/dev/null | grep -q '^ssh-agent$' && [ -S "$env_sock" ]; then
        export SSH_AGENT_PID="$env_pid"
        export SSH_AUTH_SOCK="$env_sock"
        return 0
    else
        # 清理失效的环境文件，避免加载旧值
        [ -f "$AGENT_ENV_FILE" ] && rm -f "$AGENT_ENV_FILE"
        return 1
    fi
}

# 函数2：检查密钥是否已活跃（未超时、已添加）
is_key_active() {
    # 先检查私钥/公钥文件是否存在
    local pub_key_file="${SSH_PRIVATE_KEY}.pub"
    local key_fingerprint
    
    # 优先从公钥提取指纹（更安全）
    if [ -f "$pub_key_file" ]; then
        key_fingerprint=$(ssh-keygen -lf "$pub_key_file" 2>/dev/null | awk '{print $2}' | head -n1)
    elif [ -f "$SSH_PRIVATE_KEY" ]; then
        key_fingerprint=$(ssh-keygen -lf "$SSH_PRIVATE_KEY" 2>/dev/null | awk '{print $2}' | head -n1)
    else
        return 1  # 密钥文件不存在
    fi

    # 检查指纹是否在agent活跃列表中
    [ -z "$key_fingerprint" ] && return 1
    ssh-add -l 2>/dev/null | grep -q "$key_fingerprint"
    return $?
}

# ========== 核心主逻辑 ==========
# 步骤1：确保ssh-agent进程有效运行（避免重复启动）
if ! validate_agent_env; then
    # 终止残留无效进程
    [ -n "$SSH_AGENT_PID" ] && kill "$SSH_AGENT_PID" 2>/dev/null
    # 启动新agent并保存环境变量（仅保留核心变量）
    eval "$(ssh-agent -s | tee >(grep -E '^SSH_(AUTH_SOCK|AGENT_PID)=' > "$AGENT_ENV_FILE"))"
    # 加载新的环境变量
    source "$AGENT_ENV_FILE" 2>/dev/null
fi

# 步骤2：仅当密钥未活跃时添加（避免重复输入密码）
if ! is_key_active && [ -f "$SSH_PRIVATE_KEY" ]; then
    ssh-add -q -t "$KEY_EXPIRE_SECONDS" "$SSH_PRIVATE_KEY" 2>/dev/null
fi

# 测试 SSH 连接 GitHub
echo "$delimiter"
echo "ssh -T git@github.com:"
ssh -T git@github.com
echo "$delimiter"

# Exported variablesssh -T git@github.com
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:"/c/Program Files/GitHub CLI/":/c/windows/system32:$PATH

dev_env_dir="/d/github_ssh/MyDevEnv"

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

# Set aliases
alias c='cp -f .bashrc ~/.bashrc'
alias v='vim ~/.bashrc'
alias s='source ~/.bashrc'
alias make='mingw32-make'
alias ga='git add'
alias gb='git branch'
alias gb_r='git branch -r'
alias gc='git checkout'
alias gco='git commit'
alias gd='git diff'
alias gf='git fetch'
alias gl='git log'
alias gl_1='git log -1'
alias gpl='git pull'
alias gpsh='git push'
alias grbs='git rebase'
alias grmt='git remote -v'
alias grst='git reset'
alias gs='git status'

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

web() { # open the web page, usage: web https://github.com
    explorer "$1"
}

help() { # cmd help info
    echo "$delimiter"
    echo "开源 = Fork → 分支 → 编码→ PR → Review → 合并(ssh: git@github.com:yt-dlp/yt-dlp.git)"
    echo "$delimiter"
    alias
    grep -n '^[a-zA-Z0-9_]*() *{' ~/.bashrc
    printf "  -usual utils:\n"
    printf "\t%s\n" "${usual_utils[@]}"
    printf "  -usual webs:\n"
    printf "\tweb %s\n" "${usual_webs[@]}"
    printf "  -usual winmtr: # git clone git@github.com:leeter/WinMTR-refresh.git\n"
    printf "\twinmtr -i 1 -s 1024 -n %s &\n" "${usual_winmtr[@]}"
}

# ========== 仅Git Bash启动时执行，source时跳过 ==========
if [[ -n "$PS1" && "$0" =~ bash && -z "${BASH_SOURCE[1]}" ]]; then
    # 显示一定义的命令行别名
    alias
    # 核心命令：查找.bashrc中所有函数定义，显示行号+函数名开头
    grep -n '^[a-zA-Z0-9_]*() *{' ~/.bashrc
    echo "******************* Source the env and aliases are set done! ****************************"
else

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
