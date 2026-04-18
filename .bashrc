#!/bin/bash

# 定义行分隔符，宽度84个字符
export delimiter="============================================================================================="

# 默认环境路径
export dev_env_dir="/d/github_ssh/MyDevEnv"

export BASH_LIB_PATH="$dev_env_dir/.bash_lib"
export PATH="$BASH_LIB_PATH:$PATH"
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:/d/msys64/ucrt64/bin:"/c/Program Files/GitHub CLI/":/c/windows/system32:"/d/Program Files/Putty/":$PATH

cur_path=$PWD

# 每次终端启动自动导入color回显库--color_echo
if [[ -f "${BASH_LIB_PATH}/color_output.sh" ]]; then
    source "${BASH_LIB_PATH}/color_output.sh"
else
    echo -e "\x1b[31m${BASH_LIB_PATH}/color_output.sh not exists!!!\x1b[0m"
fi

# 切换到默认路径
if [[ -z "$dev_env_dir" ]]; then
    color_echo "RED" "⚠️ dev_env_dir is empty!"
    echo "$delimiter"
    return
elif [ -d "$dev_env_dir" ]; then
    cd "$dev_env_dir" || {
        echo "⚠️ Failed to cd to $dev_env_dir!"
        echo "$delimiter"
        return
    }
else
    echo "$delimiter"
    color_echo "RED" "⚠️ Directory $dev_env_dir not found!"
    echo "$delimiter"
    return
fi

#############################################################################################
alias c='cp -f $dev_env_dir/.bashrc ~/.bashrc' # cp local .bashrc to ~/.bashrc
alias u='cp -f ~/.bashrc $dev_env_dir/.bashrc' # update local .bashrc with ~/.bashrc
alias s='source ~/.bashrc'
alias a='grep ^alias ~/.bashrc'
alias f='functions'
alias h='help'
alias hi='helpInfo'
alias lc='list_color_functions'
alias w='usual_webs'
alias uu='usual_utils'
alias us='usual_shells'
alias uw='usual_winmtr'
alias v='vim ~/.bashrc'
alias vh='vim $dev_env_dir/helpInfo.sh'
alias vf='vim $dev_env_dir/functions.sh'
alias vc='vim ${BASH_LIB_PATH}/color_output.sh'
alias vssh='vim $dev_env_dir/ssh-agent.sh'
alias cdd='cd $dev_env_dir'
alias cd32='cd "/d/Program Files/FS_EMBSIM_LOCAL-V2.4.7/sources/project_STM32G030C8T6_NB860"'

source $dev_env_dir/alias.sh
source $dev_env_dir/helpInfo.sh
source $dev_env_dir/functions.sh
source $dev_env_dir/ssh-agent.sh

#############################################################################################

# TODO信息在此处扩展添加
todoList=(
	"TODO: 动态添加常用工具安装路径到PATH，比如msys64默认安装为 C:\msys64， 也可能在其他盘。"
)

# TODO: 自动查找 Git 安装根目录（不写死）
# GIT_ROOT=$(dirname "$(which git)")/..
# MINGW_BIN="$GIT_ROOT"
# 自动添加 Git/mingw64 工具路径
# export PATH=$MINGW_BIN:$PATH
# export BASH_LIB_PATH="$dev_env_dir/.bash_lib"


# help信息在此处扩展添加
helpList=("alias: a" "helpInfo: hi" "functions: f" "list_color_functions: lc")

######################## 打印帮助信息函数  ###############################
function help() { # show help info
    for item in "${helpList[@]}"; do
        # 彩色输出函数名 + 说明
        color_echo "CYAN" "• ${item}"
    done

    color_echo "CYAN" "• type -f NAME"
    
    grep "^alias .*=" ~/.bashrc 

    for item in "${todoList[@]}"; do
        color_echo "YELLOW" "⨀ ${item}"
    done
}

# ================== 仅Git Bash启动时执行，source时跳过 ==================
if [[ -n "$PS1" && "$0" =~ bash && -z "${BASH_SOURCE[1]}" ]]; then
    # 显示help信息
    help
    cd $cur_path
else
    color_echo "PURPLE" "\$PS1=$PS1"
    # 测试 SSH 连接 GitHub
    echo "$delimiter"
    color_echo "ORANGE" "ssh -T git@github.com:"
    ssh -T git@github.com
    echo "$delimiter"

    echo "📂 切换到目录：$dev_env_dir"
    ls *.md -1 2>/dev/null || color_echo "RED" "📄 No .md files found in $dev_env_dir"
    echo "$delimiter"

    toolLists=("git" "gh" "gcc" "g++" "make" "python" "arm-none-eabi-gcc")
    ############## 打印工具信息函数
    print_tool_info() {
        local tool="$1"  # 函数内可用local

	color_echo "GREEN" "$tool:"
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
    for item in "${toolLists[@]}"; do
        print_tool_info ${item}
        echo "$delimiter"
    done

    
    # ========================== 检查 gh 登录状态
    color_echo "GREEN" "gh auth status:" 
    gh auth status

    # 测试列出仓库
    color_echo "GREEN" "gh repo list:"
    gh repo list

    blink_color_echo "GREEN" "*******  git-bash  *******"
    color_echo "BLUE" "$(cat ~/.minttyrc)"
    blink_color_echo "GREEN" "******* tty-scheme *******"
    
    # ========================== 更新.bashrc并检查git状态
    if [[ -d "$dev_env_dir/.git" ]]; then
        cp -f ~/.bashrc "$dev_env_dir/"
        git status
    else
        color_echo "RED" "⚠️ $dev_env_dir is not a Git repository!"
    fi

fi
