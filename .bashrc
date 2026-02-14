# ssh-agent 自动启动
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

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
	      "www.yyzlab.com.cn")    

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
    alias
    grep -n '^[a-zA-Z0-9_]*() *{' ~/.bashrc
    printf "  -usual utils:\n"
    printf "\t%s\n" "${usual_utils[@]}"
    printf "  -usual webs:\n"
    printf "\tweb %s\n" "${usual_webs[@]}"
    printf "  -usual winmtr:\n"
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
    # 定义共享分隔符（块内变量，不用local）
    delimiter="------------------------------------------------------------------------------------"

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
            unset delimiter
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
    
    # 验证ssh帐户
    echo "ssh -T git@github.com:"
    ssh -T git@github.com
    echo "$delimiter"

    # 更新.bashrc并检查git状态（增加git仓库校验）
    if [[ -d "$dev_env_dir/.git" ]]; then
        cp -f ~/.bashrc "$dev_env_dir/"
        git status
    else
        echo "⚠️ $dev_env_dir is not a Git repository!"
        echo "$delimiter"
    fi

    # 清理变量（块内变量，unset即可）
    unset delimiter
fi
# ========== 条件判断结束 ==========
