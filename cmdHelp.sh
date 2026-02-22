#!/bin/bash

# 命令手册核心脚本 - cmdhelp
# 使用方式：
# 1. 查看所有可用主题：cmdhelp
# 2. 查看指定主题所有命令：cmdhelp git（无关键词时显示该主题全部）
# 3. 主题内精准检索：cmdhelp git clone（仅显示含关键词的命令）

cmdhelp_delimiter="============================"


# ==================== 自定义命令库（按主题分类，可自由扩展） ====================
declare -A CMD_MANUAL
CMD_MANUAL=(
  # Git 相关（主题：git）
  ["git|查看分支"]="git branch -a                          # 查看本地+远程所有分支"
  ["git|切换分支"]="git checkout 分支名                     # 切换到指定分支"
  ["git|克隆Repo"]="git clone git@github.com:user/xxx.git   # 克隆指定xxx库(SSH方式)"
  ["git|创建并切换分支"]="git checkout -b 新分支名           # 新建分支并切换"
  ["git|拉取远程代码"]="git pull origin 分支名               # 拉取指定远程分支代码"
  ["git|推送代码"]="git push origin 分支名                   # 推送本地分支到远程"
  ["git|提交修改"]="git commit -m '提交信息'                # 提交暂存区修改"

  # SSH 相关（主题：ssh）
  ["ssh|测试GitHub连接"]="ssh -T git@github.com             # 验证GitHub SSH连接"
  ["ssh|查看agent缓存"]="ssh-add -l                         # 查看agent中缓存的私钥"
  ["ssh|添加私钥到agent"]="ssh-add ~/.ssh/id_ed25519        # 将私钥添加到agent"
  ["ssh|启动agent"]="eval \$(ssh-agent -s)                  # 启动ssh-agent进程"

  # Linux 基础（主题：linux）
  ["linux|查看进程"]="ps -ef | grep 进程名                  # 过滤查看指定进程"
  ["linux|终止进程"]="kill -9 PID                           # 强制终止指定PID进程"
  ["linux|查看磁盘"]="df -h                                 # 人性化显示磁盘占用"
  ["linux|查看目录大小"]="du -sh 目录名                     # 查看目录总大小"

  # Docker 相关（主题：docker）
  ["docker|查看运行容器"]="docker ps                        # 查看正在运行的容器"
  ["docker|查看所有容器"]="docker ps -a                     # 查看所有容器（含停止）"
  ["docker|启动容器"]="docker start 容器ID/名称             # 启动指定容器"
)

# ==================== 辅助函数：提取所有可用主题 ====================
get_all_topics() {
  # 去重并提取所有主题
  local topics=$(for key in "${!CMD_MANUAL[@]}"; do echo "$key" | cut -d'|' -f1; done | sort -u)
  echo "$topics"
}

# ==================== 辅助函数：提取所有可用主题（适配Windows） ====================
get_all_topics() {
  # 手动定义主题列表（避免Windows下管道命令兼容问题）
  # 新增/删除主题时，同步修改这里即可
  local topics=("git" "ssh" "linux" "docker")
  echo "${topics[@]}"
}

# ==================== 核心检索逻辑（适配Windows） ====================
cmdhelp() {
  # 处理输入参数（主题 + 二次检索关键词）
  local search_topic="$1"
  local search_keyword="$2"

  # 第一步：无任何参数（仅查看可用主题）
  if [[ -z "$search_topic" ]]; then
    echo -e "\033[32m$cmdhelp_delimiter 可用命令主题 $cmdhelp_delimiter\033[0m"
    local all_topics=($(get_all_topics))
    for topic in "${all_topics[@]}"; do
      echo -e "  \033[34m$topic\033[0m"
    done
    echo -e "\n使用示例：cmdhelp git（查看Git命令） | cmdhelp git clone（检索Git的clone命令）"
    return 0
  fi

  # 第二步：校验输入的主题是否存在（适配Windows）
  local all_topics=($(get_all_topics))
  local topic_exists=0
  for topic in "${all_topics[@]}"; do
    if [[ "$topic" == "$search_topic" ]]; then
      topic_exists=1
      break
    fi
  done

  if [[ $topic_exists -eq 0 ]]; then
    echo -e "\033[31m⚠️  不存在该主题！\033[0m"
    echo -e "\033[32m可用主题：\033[0m${all_topics[*]}"
    return 1
  fi

  # 第三步：检索指定主题的命令（无关键词显示全部，有关键词筛选）
  echo -e "\033[32m$cmdhelp_delimiter $search_topic 主题命令 $cmdhelp_delimiter\033[0m"
  local match_count=0
  # 遍历命令库（避免cut命令，直接拆分字符串）
  for key in "${!CMD_MANUAL[@]}"; do
    # 拆分主题和描述（不用cut，用bash内置字符串处理）
    local topic="${key%%|*}"  # 取|前面的内容（主题）
    local desc="${key#*|}"    # 取|后面的内容（描述）
    local cmd="${CMD_MANUAL[$key]}"

    # 仅处理匹配的主题
    if [[ "$topic" == "$search_topic" ]]; then
      # 无关键词：直接显示；有关键词：筛选含关键词的命令
      if [[ -z "$search_keyword" || "$desc" == *"$search_keyword"* || "$cmd" == *"$search_keyword"* ]]; then
        echo -e "\033[34m→\033[0m $desc"
        echo -e "  \033[32m$cmd\033[0m\n"
        ((match_count++))
      fi
    fi
  done

  # 第四步：主题存在但无匹配关键词的提示
  if [[ $match_count -eq 0 && -n "$search_keyword" ]]; then
    echo -e "\033[31m⚠️  $search_topic 主题下未找到含「$search_keyword」的命令！\033[0m"
    echo -e "该主题下所有命令：\n"
    # 重新打印该主题全部命令
    for key in "${!CMD_MANUAL[@]}"; do
      local topic="${key%%|*}"
      if [[ "$topic" == "$search_topic" ]]; then
        local desc="${key#*|}"
        local cmd="${CMD_MANUAL[$key]}"
        echo -e "\033[34m→\033[0m $desc"
        echo -e "  \033[32m$cmd\033[0m\n"
      fi
    done
  fi
}

# 暴露命令到全局
export -f cmdhelp
