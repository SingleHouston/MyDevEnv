#!/bin/bash

# 核心配置（根据实际情况修改）
AGENT_ENV_FILE="$HOME/.ssh/agent.env"   # 保存agent环境变量的文件
SSH_PRIVATE_KEY="$HOME/.ssh/id_ed25519" # 私钥文件路径
KEY_EXPIRE_SECONDS=3600                 # 密钥超时时间（1小时）
SSH_AGENT_PID=""                        # 初始化SSH代理进程ID为空

# 函数1：验证ssh-agent环境是否有效（进程存活+通信正常）
validate_agent_env() {
    local env_pid env_sock

    # 从环境文件提取核心变量（过滤冗余行，清理格式）
    if [ -f "$AGENT_ENV_FILE" ]; then
        # 正则表达式过滤 
	env_pid=$(grep -Eo '^SSH_AGENT_PID=[0-9]+' "$AGENT_ENV_FILE" | grep -Eo '[0-9]+')
	# 替换原 env_sock 提取行，用 sed 正则一步到位
	env_sock=$(grep -E '^SSH_AUTH_SOCK=' "$AGENT_ENV_FILE" | sed -E 's/^SSH_AUTH_SOCK=([/a-zA-Z0-9._-]+);.*$/\1/')
    fi

    SSH_AGENT_PID="$env_pid"
    
    # 打印检验存储的AGENT_ENV_FILE内容以及SSH_AGENT_PID
    printf "${CYAN}env_pid=%s, env_sock=%s\n${RESET}" "$env_pid" "$env_sock"

    # 校验1：PID非空 + 进程存在
    if [ -z "$env_pid" ] || ! ps -p "$env_pid" > /dev/null 2>&1; then
        [ -f "$AGENT_ENV_FILE" ] && rm -f "$AGENT_ENV_FILE"
	    # 打印黄色警告信息
	    printf "${YELLOW}validate_agent_env(): return 1, rm -f the invalid AGENT_ENV_FILE as env_pid( %s ) is null or ps -p %s return false.\n${RESET}" "$env_pid" "$env_pid"
        return 1
    fi

    # 校验2：提取进程名（兼容所有格式）
    local proc_name=$(ps -p "$env_pid" 2>/dev/null | awk 'NR>1 {print $NF}' | cut -d'/' -f4 | head -n1)

    # 校验3：进程是ssh-agent + 套接字有效
    if [ "$proc_name" = "ssh-agent" ] && [ -S "$env_sock" ]; then
	    export SSH_AGENT_PID="$env_pid"
        export SSH_AUTH_SOCK="$env_sock"
	    # 打印绿色提示信息
	    printf "${GREEN}validate_agent_env(): return 0: SSH_AGENT_PID( %s ) exists, AGENT_ENV_FILE is valid.\n${RESET}" "$env_pid"
        return 0
    else
        [ -f "$AGENT_ENV_FILE" ] && rm -f "$AGENT_ENV_FILE"
	    # 打印黄色警告信息
	    printf "${YELLOW}validate_agent_env(): return 1, as proc_name( %s ) isn't ssh-agent or env_sock( %s ) isn't socket.\n${RESET}" "$proc_name" "$env_sock"
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
    return $? # $? 为管道命令整体返回结果: ssh-add -l 2>/dev/null | grep -q "$key_fingerprint"
}

# ======================================= 核心主逻辑 =============================================
# 步骤1：确保ssh-agent进程有效运行（避免重复启动）
if ! validate_agent_env; then
    [ -n "$SSH_AGENT_PID" ] && kill "$SSH_AGENT_PID" 2>/dev/null && printf "${YELLOW} Kill SSH_AGENT_PID( %s ).\n${RESET}" "$SSH_AGENT_PID"
    
    # 直接筛选核心变量，避免进程替换
    ssh-agent -s | grep -E '^SSH_(AUTH_SOCK|AGENT_PID)=' > "$AGENT_ENV_FILE"
    # 重新执行ssh-agent -s并eval（获取完整环境变量）
    eval "$(ssh-agent -s 2>/dev/null)"

    printf "${YELLOW} Restart new ssh-agent -s and redirect to AGENT_ENV_FILE ( %s ).\n${RESET}" "$AGENT_ENV_FILE"
    cat "$AGENT_ENV_FILE"
    source "$AGENT_ENV_FILE" 2>/dev/null
fi

# 步骤2：仅当密钥未活跃时添加（避免重复输入密码）
if ! is_key_active && [ -f "$SSH_PRIVATE_KEY" ]; then
    ssh-add -q -t "$KEY_EXPIRE_SECONDS" "$SSH_PRIVATE_KEY" 2>/dev/null
fi
