# Exported variables
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:$PATH
# Set aliases 
alias edit='vim ~/.bashrc'
alias src='source ~/.bashrc'
alias open='explorer $(cygpath -w "$(pwd)")'
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
alias grb='git rebase'
alias grt='git reset'
alias gs='git status'
# ========== 仅Git Bash启动时执行，source时跳过 ==========
if [[ -n "$PS1" && "$0" =~ bash && -z "${BASH_SOURCE[1]}" ]]; then
    alias
    echo "----------------------------- Aliases set done! -----------------------------------------"
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
        "$tool" --version | head -n 1
        echo "$delimiter"
    }

    # 调用函数查询工具信息
    print_tool_info "python"
    print_tool_info "gcc"
    print_tool_info "arm-none-eabi-gcc"
    print_tool_info "git"

    # 常用网站列表
    echo "🔗 Usual websites:"
    echo "explorer.exe https://github.com"
    echo "explorer.exe https://test.ustc.edu.cn"
    echo "explorer.exe https://www.yyzlab.com.cn/aiEliteJobClass/1957271757362696205"
    echo "$delimiter"

    # 展示MyDevEnv中的md文件（核心修正：去掉local，增加路径校验）
    dev_env_dir="/d/gitHub/MyDevEnv"  # 块内变量，不用local
    # 先校验路径是否非空
    if [[ -z "$dev_env_dir" ]]; then
        echo "$delimiter"
        echo "⚠️ dev_env_dir is empty!"
        echo "$delimiter"
    elif [ -d "$dev_env_dir" ]; then
        cd "$dev_env_dir" || {
            echo "$delimiter"
            echo "⚠️ Failed to cd to $dev_env_dir!"
            echo "$delimiter"
            # cd失败时跳过后续git操作
            unset delimiter dev_env_dir
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

    # 更新.bashrc并检查git状态（增加git仓库校验）
    if [[ -d "$dev_env_dir/.git" ]]; then
        cp -f ~/.bashrc "$dev_env_dir/"
        git status
    else
        echo "$delimiter"
        echo "⚠️ $dev_env_dir is not a Git repository!"
        echo "$delimiter"
    fi

    # 清理变量（块内变量，unset即可）
    unset delimiter dev_env_dir
fi
# ========== 条件判断结束 ==========
