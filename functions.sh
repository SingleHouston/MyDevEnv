#!/bin/bash

source color_output.sh

utils=("man bash # show the manual of bash"
       "bash -n ~/.bashrc # 仅解析检查脚本正确性但不执行~/.bashrc"
       "cygpath -w/-u # 转换成windows/unix路径"
       "pacman -S/-R/-Syu # 在 MSYS2 MINGW64 环境下: 安装/卸载/更新 包"
       "pip install/uninstall/install -U # 安装/卸载/更新 python库"
       "declare -f; type -t; # 查询util的类型 "
       "gpg --full-generate-key # 生成GPG密钥对（2.1.17之后的版本）"
       "gpg --list-secret-keys --keyid-format=long # 列出本地所有GPG密钥（查看刚生成的密钥）")

webs=("web https://github.com"
      "web https://www.msys2.org"
      "web https://www.msys2.org/docs/environments/"
      "web https://www.sharetechnote.com/  # RAN Technology ShareNotes 技术网站"
      "web https://www.etsi.org/deliver/etsi_ts/138300_138399/  # 3GPP Specification on ETSI 官方 (38 Series)"
      "web https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads  # arm tool-chain for downloading 官网"
      "web https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#256-colors # colors code"
      "web https://www.yyzlab.com.cn/aiEliteJobClass/1957271757362696205  # yyzlab - 华清远见")

# ================= 函数定义：winmtr测试工具测试常用网址的时延 =================

# 定义 winmtr 测试任务列表（格式："备注|命令"）
declare -a WINMTR_TASKS=(
    "测试 github.com 延迟|winmtr -i 1 -s 1024 -n github.com"
    "测试 www.yyzlab.com.cn 延迟|winmtr -i 1 -s 1024 -n www.yyzlab.com.cn"
    "测试腾讯云新加坡 CDN 主节点|winmtr -i 1 -s 1024 -n 43.174.246.25"
    "测试腾讯云新加坡 CDN 备用节点|winmtr -i 1 -s 1024 -n 43.174.247.25"
    "测试杭州阿里云内地服务器|winmtr -i 1 -s 1024 -n 39.103.225.56"
)

# 定义退出控制变量
declare -a EXIT_FLAG=0

# 全局变量：保存默认的 SIGINT 处理逻辑
DEFAULT_SIGINT_TRAP=""

# 函数：处理 Ctrl+C 信号（仅脚本内生效）
handle_sigint() {
    # echo -e "\n\n⚠️  检测到 Ctrl+C，正在退出..."
    export PS1="$ORIG_PS1"
    pkill -f "winmtr -i 1 -s 1024 -n" >/dev/null 2>&1
    echo -e "👋 已退出 winmtr 测试模式，恢复原始提示符"
    
    # 恢复系统默认的 SIGINT 处理
    trap "$DEFAULT_SIGINT_TRAP" SIGINT

    EXIT_FLAG=1
}

# 函数：初始化信号处理（兼容 Git Bash）
init_sigint_trap() {
    # 步骤1：获取当前 SIGINT 的处理规则（兼容单/双引号）
    local trap_output=$(trap -p SIGINT)

    # 步骤2：按空格分割，提取核心处理规则（兼容所有格式）
    # 示例输出：trap -- "" SIGINT → 提取 ""；trap -- 'echo test' SIGINT → 提取 'echo test'
    DEFAULT_SIGINT_TRAP=$(echo "$trap_output" | awk '{print $3}')

    # 步骤3：处理空值（如果默认无自定义处理，设为 "-" 表示恢复默认）
    if [[ -z "$DEFAULT_SIGINT_TRAP" || "$DEFAULT_SIGINT_TRAP" == '""' || "$DEFAULT_SIGINT_TRAP" == "''" ]]; then
        DEFAULT_SIGINT_TRAP="-"
    fi

    # 步骤4：注册自定义 SIGINT 处理
    trap handle_sigint SIGINT
}

# 函数：恢复默认信号处理（脚本正常退出时调用）
restore_sigint_trap() {
    trap "$DEFAULT_SIGINT_TRAP" SIGINT
}

# 函数：打印任务列表（仅首次执行时显示）
show_task_list() {
    echo -e "\n===== WinMTR 测试任务列表 ====="
    for index in "${!WINMTR_TASKS[@]}"; do
        task_note=$(echo "${WINMTR_TASKS[$index]}" | cut -d'|' -f1)
        echo "[$((index+1))] $task_note"
    done
    echo "Input cmd No( 1~${#WINMTR_TASKS[@]}, q/quit ):"
}

# 函数：执行选中的任务（winmtr 后台运行+重定向输出）
execute_task() {
    local selected_num=$1
    
    # 退出逻辑
    if [[ "$selected_num" == "q" || "$selected_num" == "quit" ]]; then
        export PS1="$ORIG_PS1"
        pkill -f "winmtr -i 1 -s 1024 -n" >/dev/null 2>&1
        echo -e "\n👋 退出 winmtr 测试模式"	
	restore_sigint_trap
	EXIT_FLAG=1
	
	return 0
    fi

    # 校验数字输入
    if ! [[ "$selected_num" =~ ^[0-9]+$ ]]; then
        echo "❌ 错误：请输入数字序号（1~${#WINMTR_TASKS[@]}），或输入 q 退出"
        return 1
    fi

    # 校验序号范围
    local task_index=$((selected_num-1))
    if [[ $task_index -lt 0 || $task_index -ge ${#WINMTR_TASKS[@]} ]]; then
        echo "❌ 错误：序号超出范围！有效序号是 1~${#WINMTR_TASKS[@]}"
        return 1
    fi

    # 拆分命令和备注
    task_command=$(echo "${WINMTR_TASKS[$task_index]}" | cut -d'|' -f2)
    task_note=$(echo "${WINMTR_TASKS[$task_index]}" | cut -d'|' -f1)
    # 生成临时日志文件（避免 winmtr 输出占用终端）
    log_file="/tmp/winmtr_${task_index}_$(date +%s).log"
    # 执行 winmtr：后台运行 + 输出重定向到日志文件
    nohup $task_command & > "$log_file" 2>&1 &
    # 下一次的命令输入提示
    show_task_list
    echo "------------------------------"
}

function usual_winmtr() { # 打印网络测试结果
    # 保存原始提示符
    export ORIG_PS1="$PS1"
    
    # 设置自定义提示符
    export PS1="usual_winmtr> "
    
    # 初始化EXIT_FLAG
    EXIT_FLAG=0
    
    # 初始化信号处理函数: CTRL+C
    init_sigint_trap
    
    # 打印任务列表
    echo -e "github repo: git clone git@github.com:leeter/WinMTR-refresh.git"
    show_task_list
    
    # 循环读取输入（直到退出）
    while [[ $EXIT_FLAG -eq 0 ]]; do
        read -r input  # -r 避免输入特殊字符被转义
        if [[ -n "$input" && $EXIT_FLAG -eq 0 ]]; then
            execute_task "$input"
            # 退出时终止循环
            if [[ $EXIT_FLAG -eq 1 ]]; then
                break
            fi
        fi
    done

    # fixme: the log file wasn't generated
    # echo -e "\n▁▁▁▁ 测试log: $log_file ▁▁▁▁"
}

# ================================================================

function open() { # 自定义函数open: open ./ or open /d/github_ssh/
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

TARGET_DIR="/d/github_ssh"
function github_repos() { # 显示本地的github_repos，如果全的话，建议输出到github_repos.md
    if [ ! -d $TARGET_DIR ]; then
	echo -e "\033[31m $TARGET_DIR NOT EXISTS!\n"
	exit 1
    fi
	
    printf " -github_repos:\n"
    default_path="$(pwd)"
    # 遍历目标目录下的所有子文件夹
    for repo_dir in "$TARGET_DIR"/*/; do
        # 提取仓库名称（去掉路径，只保留文件夹名）
        repo_name=$(basename "$repo_dir")
        # 确保路径是绝对路径且无多余斜杠
        repo_path=$(cd "$repo_dir" && pwd)

        # 打印仓库基本信息（带颜色高亮）
        echo -e "\033[32m【仓库名称】: $repo_name\033[0m"
        echo -e "【仓库路径】: $repo_path"
        echo -e "【远程仓库信息】:"

        # 进入仓库目录并执行git命令
        cd "$repo_path" || {
            echo -e "    \033[33m警告：无法进入目录 $repo_path\033[0m"
            echo -e "\033[37m----------------------------------------------\033[0m\n"
            continue
        }

        # 检查是否是Git仓库
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            # 执行git remote -v，格式化输出
            git remote -v | grep fetch
        else
            echo -e "    \033[33m警告：该文件夹不是Git仓库！\033[0m"
        fi

        # 分隔线
        echo -e "\n"
    done

    cd "$default_path"
}

function web() { # 自定义函数web: web https://github.com
    explorer "$1"
}

function usual_utils() { # 打印常用工具命令
        printf "  -usual utils:\n"
        printf "\t%s\n" "${utils[@]}"
}

function usual_webs() { # 打印常用网址
        printf "  -usual webs:\n"
        printf "\t%s\n" "${webs[@]}"
}

shells=(
	# @1
	"$BOLD$BLUE
        # @1. 函数定义格式
        $CYAN
        # 格式1：最简定义（推荐）
        $YELLOW
        函数名() {
            $PURPLE
            # 用 \$1 接收第1个参数，\$2 接收第2个，依此类推
            $RED
            # \$0 是脚本名称"/usr/bin/bash"，不是函数参数
            $WHITE
            逻辑代码
        $YELLOW}

        $CYAN
        # 格式2：加 function 关键字（兼容所有 Shell）
        $YELLOW
        "function" 函数名() {
            $WHITE
	    逻辑代码
        $YELLOW
        }
	$RESET"
        
	# @2
	"$BOLD$BLUE
        # @2. 函数调用示例代码
        $WHITE
        #!/bin/bash

        # 定义带参数的函数：校验 ssh-agent 进程是否有效
        # 参数1：要校验的 PID
        # 参数2：要校验的套接字路径
        $YELLOW
        "check_ssh_agent"() {
          $CYAN
          # 接收参数
          $PURPLE
          "local" pid=\"\$1\"   # 第1个参数：PID
          $PURPLE
          "local" sock=\"\$2\"  # 第2个参数：套接字路径

          $WHITE
          # 空值校验
          if [ -z \"\$pid\" ] || [ -z \"\$sock\" ]; then
            echo \"错误：必须传入 PID 和 套接字路径！\"
            return 1  # 返回非0表示失败
          fi

          # 核心逻辑：校验进程+套接字
          if ps -p \"\$pid\" > /dev/null 2>&1 && [ -S \"\$sock\" ]; then
            echo \"✅ ssh-agent(PID:\$pid) 有效，套接字：\$sock\"
            return 0  # 返回0表示成功
          else
            echo \"❌ ssh-agent(PID:\$pid) 无效，套接字: \$sock\"
            return 1
          fi
        $YELLOW}

        # ==================== 调用函数（传参）====================
        $CYAN
        # 调用方式1：直接传固定值
        $YELLOW
        "check_ssh_agent" 3315 \"/c/Users/pc/.ssh/agent/s.Y8NeWIWRZI.agent.1cD36ZLtNF\"

        $CYAN
        # 调用方式2：传变量（实战常用)
        $WHITE
        agent_pid=3315
        agent_sock=\"/c/Users/pc/.ssh/agent/s.Y8NeWIWRZI.agent.1cD36ZLtNF\"
        $YELLOW
        "check_ssh_agent" \"\$agent_pid\" \"\$agent_sock\"  # 变量加双引号，避免空格/特殊字符问题

        $CYAN
        # 调用方式3：接收函数返回值
        $YELLOW
        if check_ssh_agent \"\$agent_pid\" \"\$agent_sock\"; then
          $WHITE
          echo \"函数执行成功，复用现有 ssh-agent\"
        else
          echo \"函数执行失败，重启 ssh-agent\"
          eval \$(ssh-agent -s)  # 重启进程
        fi
	$RESET
	")

# 注意: 为了保持下表shell_conditions列打印对齐，变量名长度刻意与打印出的字符串长度人为保证一致
var="\"\$var\""
file="\"\$file\""
dir="\"\$dir\""
path="\"\$path\""
ssh_agent_s___="\"\$(ssh-agent -s)\""
x="\$?"
return_comment="${CYAN}0→true，${RED}非0→false$RESET"
shell_conditions=(
    "$BOLD$BLUE
        # @3. 脚本判断运算符
        $RESET
        运算符    语法                  含义                               返回值(真 / 假)    典型应用场景\n
        ===============================================================================================================================
        -z   [[ -z ${var} ]]            检查变量值是否为空字符串 (长度 0)  空→真，非空→假     如 if [ -z \"\$PID\" ]) 返回值是否为空\n
        -n   [[ -n ${var} ]]            检查变量值是否非空字符串(长度>0)   非空→真，空→假     如 if [ -n \"\$1\" ]) 进程名是否有效\n
        -S   [[ -S ${file} ]]           检查路径是否是套接字文件(socket)   是→真，否→假       套接字是否有效 if [ -S \"\$SOCK\" ]\n
        -f   [[ -f ${file} ]]           检查路径是否是普通文件(非目录)     是→真，否→假       私/公钥存在? if [ -f \"\$SSH_PRIVATE_KEY\" ]\n
        -d   [[ -d ${dir} ]]            检查路径是否是目录                 是→真，否→假       校验目录是否存在 if [ -d \"\$HOME/.ssh\" ]\n
        -e   [[ -e ${path} ]]           检查路径(文件/目录)是否存在        是→真，否→假       通用存在性校验(兼容文件/目录/套接字)\n         
        eval [ eval ${ssh_agent__s__} ] 执行字符串里的命令                 成功→0，失败→非0   动态执行命令（如启动ssh-agent）\n
        $x   [ return $x ]              上一条命令是否执行成功             ${return_comment}  判断执行结果 if [ \$? -eq 0 ]; then\n
        *******************************************************************************************************************************
        !    ! func_xxx                 函数返回值取反                     ${return_comment}  函数示例
                                                                                              function f1()
                                                                                              {
                                                                                                 if true
                                                                                                 ${CYAN}
                                                                                                     return 0; 
                                                                                                 $RESET
                                                                                                 else 
                                                                                                 ${RED}
                                                                                                    return 1; 
                                                                                                 $RESET
                                                                                                 fi
                                                                                              }
                                                                                              
                                                                                              # 判断f1()返回值
                                                                                              ${YELLOW}
                                                                                              if ! f1; then 
                                                                                                echo \"f1 return 1\"
                                                                                              fi
                                                                                              $RESET
        ===============================================================================================================================
    ")
	
function usual_shells() { # 打印shell脚本语法
        echo -e "  -usual usage of shells:\n"
        echo -e "\t${shells[@]}"
	    printf "${shell_conditions}"
}

function vi_cheatsheet() { # vi/vim 常用快捷键查询函数（可直接在终端输入 vi_cheatsheet 调用）
    # 打印标题
    echo -e "\n${BOLD}${BLUE}===== VI/VIM 常用快捷键速查 =====${RESET}\n"

    # 1. 模式切换
    echo -e "${BOLD}${YELLOW}【模式切换】${RESET}"
    echo -e "  ${GREEN}i${RESET}        → 进入插入模式（光标前）"
    echo -e "  ${GREEN}a${RESET}        → 进入插入模式（光标后）"
    echo -e "  ${GREEN}ESC${RESET}      → 回到普通模式"
    echo -e "  ${GREEN}:${RESET}        → 进入底行模式（命令模式）"
    echo -e "  ${GREEN}Ctrl + v${RESET} → 进入可视化块模式\n"

    # 2. 光标移动（普通模式）
    echo -e "${BOLD}${YELLOW}【光标移动】${RESET}"
    echo -e "  ${GREEN}hjkl${RESET}      → 左/下/上/右（替代方向键）"
    echo -e "  ${GREEN}0${RESET}        → 跳到行首"
    echo -e "  ${GREEN}$${RESET}        → 跳到行尾"
    echo -e "  ${GREEN}gg${RESET}       → 跳到文件首行"
    echo -e "  ${GREEN}G${RESET}        → 跳到文件尾行"
    echo -e "  ${GREEN}5G${RESET}       → 跳到第5行\n"

    # 3. 编辑/删除（高频）
    echo -e "${BOLD}${YELLOW}【编辑/删除】${RESET}"
    echo -e "  ${GREEN}dd${RESET}       → 剪切（删除）当前行"
    echo -e "  ${GREEN}5dd${RESET}      → 剪切5行"
    echo -e "  ${GREEN}dw${RESET}       → 删除当前单词"
    echo -e "  ${GREEN}diw${RESET}      → 删除当前单词（含符号）"
    echo -e "  ${GREEN}d0${RESET}       → 删除光标到行首"
    echo -e "  ${GREEN}d\$${RESET}       → 删除光标到行尾"
    echo -e "  ${GREEN}di{${RESET}      → 删除大括号内内容（保留括号）"
    echo -e "  ${GREEN}da{${RESET}      → 删除大括号+内容\n"

    # 4. 复制/粘贴
    echo -e "${BOLD}${YELLOW}【复制/粘贴】${RESET}"
    echo -e "  ${GREEN}yy${RESET}       → 复制当前行"
    echo -e "  ${GREEN}5yy${RESET}      → 复制5行"
    echo -e "  ${GREEN}p${RESET}        → 粘贴到光标后"
    echo -e "  ${GREEN}P${RESET}        → 粘贴到光标前\n"

    # 5. 撤销/替换
    echo -e "${BOLD}${YELLOW}【撤销/替换】${RESET}"
    echo -e "  ${GREEN}u${RESET}        → 撤销上一步"
    echo -e "  ${GREEN}Ctrl + r${RESET} → 重做（取消撤销）"
    echo -e "  ${GREEN}:%s/旧/新/g${RESET} → 全文替换"
    echo -e "  ${GREEN}:%s/旧/新/gc${RESET} → 全文替换（每次确认）"
    echo -e "  ${GREEN}:5,10s/旧/新/g${RESET} → 替换5-10行\n"

    # 6. 保存/退出
    echo -e "${BOLD}${YELLOW}【保存/退出】${RESET}"
    echo -e "  ${GREEN}:w${RESET}       → 保存"
    echo -e "  ${GREEN}:q${RESET}       → 退出"
    echo -e "  ${GREEN}:wq${RESET}      → 保存并退出"
    echo -e "  ${GREEN}:q!${RESET}      → 强制退出（不保存）"
    echo -e "  ${GREEN}:w!${RESET}      → 强制保存\n"

    # 7. 其他实用
    echo -e "${BOLD}${YELLOW}【其他实用】${RESET}"
    echo -e "  ${GREEN}/关键词${RESET}     → 向下搜索关键词"
    echo -e "  ${GREEN}?关键词${RESET}     → 向上搜索关键词"
    echo -e "  ${GREEN}n${RESET}        → 跳到下一个搜索结果"
    echo -e "  ${GREEN}N${RESET}        → 跳到上一个搜索结果"
    echo -e "  ${GREEN}:set nu${RESET}   → 显示行号"
    echo -e "  ${GREEN}:set nonu${RESET} → 隐藏行号"
}

functions() { # 打印自定义函数
        color_echo "BLUE" "$(grep '^function [a-zA-Z0-9_]*() *{' ./functions.sh)"
}

export functions
