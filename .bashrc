#!/bin/bash

# 当前开发环境路径
dev_env_dir="/d/github_ssh/MyDevEnv"

# Set aliases
alias c='cp -f .bashrc ~/.bashrc' # cp local .bashrc to ~/.bashrc
alias u='cp -f ~/.bashrc .bashrc' # update local .bashrc with ~/.bashrc
alias s='source ~/.bashrc'
alias v='vim ~/.bashrc'
alias vh='vim $dev_env_dir/helpInfo.sh'
alias vf='vim $dev_env_dir/functions.sh'
alias vc='vim ${BASH_LIB_PATH}/color_output.sh'
alias vssh='vim $dev_env_dir/ssh-agent.sh'
alias dli='echo =============================================='
alias h='help'
alias f='functions'
alias w='usual_webs'
alias uu='usual_utils'
alias us='usual_shells'
alias uw='usual_winmtr'
alias make='mingw32-make'
alias package='pacman -Q'
alias cdd='cd $dev_env_dir'
alias cd32='cd "/d/Program Files/FS_EMBSIM_LOCAL-V2.4.7/sources/project_STM32G030C8T6_NB860"'

# 自动查找 Git 安装根目录（不写死）
# GIT_ROOT=$(dirname "$(which git)")/..
# MINGW_BIN="$GIT_ROOT"

# 自动添加 Git/mingw64 工具路径
# export PATH=$MINGW_BIN:$PATH
# export BASH_LIB_PATH="$dev_env_dir/.bash_lib"

export BASH_LIB_PATH="$dev_env_dir/.bash_lib"
export PATH="$BASH_LIB_PATH:$PATH"
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:/d/msys64/ucrt64/bin:"/c/Program Files/GitHub CLI/":/c/windows/system32:"/d/Program Files/Putty/":$PATH

# 定义行分隔符，宽度84个字符
delimiter="============================================================================================="

# 每次终端启动自动导入库（可选）
if [[ -f "${BASH_LIB_PATH}/color_output.sh" ]]; then
    source "${BASH_LIB_PATH}/color_output.sh"
else
    echo -e "\x1b[31m${BASH_LIB_PATH}/color_output.sh not exists!!!\x1b[0m"
fi

cd "$dev_env_dir"

# 帮助信息在此处扩展添加
todoList=(
	"TODO: 环境必须在/d/github_ssh/MyDevEnv下使用，其他目录下命令失效！"
	"TODO: 动态添加常用工具安装路径到PATH，比如msys64默认安装为 C:\msys64， 也可能在其他盘。"
)
helpList=("alias" "helpInfo" "functions: f" "list_color_functions")
source ./alias.sh
source ./helpInfo.sh
source ./functions.sh
source ./ssh-agent.sh

# 打印帮助信息
function help() { # show help info
    for item in "${helpList[@]}"; do
        # 彩色输出函数名 + 说明
        color_echo "CYAN" "• ${item}"
    done

    for item in "${todoList[@]}"; do
	color_echo "RED" "⨀ ${item}"
    done

    grep "^alias .*=" ~/.bashrc 

    color_echo "YELLOW" "• type -f NAME"
}

# ========== 仅Git Bash启动时执行，source时跳过 ==========
if [[ -n "$PS1" && "$0" =~ bash && -z "${BASH_SOURCE[1]}" ]]; then
    # 显示help信息
    help
else
    # 测试 SSH 连接 GitHub
    color_echo "YELLOW" "$delimiter"
    color_echo "YELLOW" "ssh -T git@github.com:"
    ssh -T git@github.com
    color_echo "YELLOW" "$delimiter"

    toolLists=("git" "gh" "gcc" "g++" "make" "python" "arm-none-eabi-gcc")
    # 通用工具信息函数
    print_tool_info() {
        local tool="$1"  # 函数内可用local

	echo "$tool:"
        # 检查工具是否存在
        if ! which "$tool" >/dev/null 2>&1; then
	    color_echo "RED" "⚠️ Tool '$tool' not found in PATH!"
            return
        fi

        # 转换路径+查版本+输出分隔符（处理空格路径）
        cygpath -w "$(which "$tool")"
        "$tool" --version
    }

    # 调用函数查询工具信息
    echo "$delimiter"
    for item in "${toolLists[@]}"; do
        print_tool_info ${item}
        echo "$delimiter"
    done


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
