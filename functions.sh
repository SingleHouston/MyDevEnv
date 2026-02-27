#!/bin/bash

source color_output.sh

utils=("bash -n ~/.bashrc # 仅解析检查脚本正确性但不执行~/.bashrc"
       "cygpath -w/-u # 转换成windows/unix路径"
       "pacman -S/-R/-Syu # 安装/卸载/更新 包"
       "pip install/uninstall/install -U # 安装/卸载/更新 python库"
       "declare -f; type -t; # 查询util的类型 "
       "gpg --full-generate-key # 生成GPG密钥对（2.1.17之后的版本）"
       "gpg --list-secret-keys --keyid-format=long # 列出本地所有GPG密钥（查看刚生成的密钥）")

webs=("https://test.ustc.edu.cn"
      "https://github.com"
      "https://www.msys2.org"
      "https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads"
      "https://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html#256-colors"
      "https://www.yyzlab.com.cn/aiEliteJobClass/1957271757362696205")

winmtr=("github.com"
        "www.yyzlab.com.cn"
        "43.174.246.25 # 腾讯云新加坡 CDN 节点，面向普通用户的主站前端 / 静态资源 / 虚拟仿真平台入口"
        "43.174.247.25 # 腾讯云新加坡 CDN 节点, CDN 集群的备用 / 分流节点"
        "39.103.225.56 # 元宇宙实验中心-后台管理系统, 杭州阿里云内地服务器，归属华清远见")

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
	$RESET"

	# @3
        "$BOLD$BLUE
        # @3. 脚本判断运算符
	$RESET
	运算符\t语法\t\t\t含义\t\t\t\t\t返回值(真 / 假)\t\t\t\t典型应用场景
	-z\t[[ -z \"\$var\" ]]\t\t检查变量值是否为空字符串 (长度 0)\t空→真，非空→假\t\t\t1. 校验环境变量是否未定义(如 if [ -z \"\$PID\" ]) 2. 校验函数返回值是否为空
	-n\t[[ -n \"\$var\" ]]\t\t检查变量值是否非空字符串(长度>0)\t非空→真，空→假\t\t\t1. 校验参数是否传入（如 if [ -n \"\$1\" ]) 2. 校验提取的进程名是否有效
	-S\t[[ -S \"\$file\" ]]\t检查路径是否是套接字文件(socket)\t是→真，否→假\t\t\t校验 ssh-agent 的套接字是否有效（if [ -S \"\$SOCK\" ])
	-f\t[[ -f \"\$file\" ]]\t检查路径是否是普通文件(非目录)\t是→真，否→假\t\t\t校验私钥 / 公钥文件是否存在(if [ -f \"\$SSH_PRIVATE_KEY\" ])
	-d\t[[ -d \"\$dir\" ]]\t\t检查路径是否是目录\t\t\t是→真，否→假\t\t\t校验目录是否存在(如 if [ -d \"\$HOME/.ssh\" ])
	-e\t[[ -e \"\$path\" ]]\t检查路径(文件 / 目录)是否存在\t存在→真，不存在→假\t\t通用存在性校验(兼容文件 / 目录 / 套接字)
	\$?\t[ return \$? ]\t\t\$?= 0 → 上一条命令执行成功；\$? ≠ 0→失败\t0→真，非0→假\t\t\t函数/命令执行结果判断（如 if [ \$? -eq 0 ]）
	eval\t[ eval \"\$(ssh-agent -s)\" ]\t执行字符串里的命令\t\t\t执行成功→0，失败→非0\t\t动态执行命令（如启动ssh-agent）
	!\t! func_xxx\t\t判断函数返回值取反\t\t${CYAN}0→true，${RED}非0→false$RESET\t\tf1() { if true return 0; else return 1; fi }; if ! f1; then echo \"f1 return 1\"; fi
	$RESET	
	")


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

function usual_winmtr() { # 打印网络测试结果
	printf "  -usual winmtr:\n"
        printf "\twinmtr -i 1 -s 1024 -n %s &\n" "${winmtr[@]}"
        echo -e "ref: git clone git@github.com:leeter/WinMTR-refresh.git"
}

function usual_shells() { # 打印shell脚本语法
        echo -e "  -usual usage of shells:\n"
        echo -e "\t${shells[@]}\n"
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
        grep '^function [a-zA-Z0-9_]*() *{' ./functions.sh
}

export functions
