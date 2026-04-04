#!/bin/bash

# 命令手册核心脚本 - helpInfo
# 使用方式：
# 1. 查看所有可用主题：helpInfo
# 2. 查看指定主题所有命令：helpInfo git（无关键词时显示该主题全部）
# 3. 主题内精准检索：helpInfo git clone（仅显示含关键词的命令）

# ==================== 自定义命令库（按主题分类，可自由扩展） ====================
declare -A CMD_MANUAL
CMD_MANUAL=(
  # Git 相关（主题：git）
  ["git|查看分支"]="git branch -a                           # 查看本地+远程所有分支"
  ["git|切换分支"]="git checkout 分支名                     # 切换到指定分支"
  ["git|克隆Repo"]="git clone git@github.com:user/xxx.git   # 克隆指定xxx库(SSH方式)"
  ["git|创建并切换分支"]="git checkout -b 新分支名          # 新建分支并切换"
  ["git|拉取远程代码"]="git pull origin 分支名              # 拉取指定远程分支代码"
  ["git|推送代码"]="git push origin 分支名                  # 推送本地分支到远程"
  ["git|提交修改"]="git commit -m '提交信息'                # 提交暂存区修改"

  # github开发步骤
  ["github|github开发流程"]="github_steps()                 # 执行函数查看具体步骤"

  # SSH 相关（主题：ssh）
  ["ssh|生成SSH密钥"]="ssh-keygen -t ed25519 -C xxx@yyy.com # 用ed25519加密算法生成密钥，-C = Comment 通常用邮箱"
  ["ssh|测试GitHub连接"]="ssh -T git@github.com             # 验证GitHub SSH连接"
  ["ssh|查看agent缓存"]="ssh-add -l                         # 查看agent中缓存的私钥"
  ["ssh|添加私钥到agent"]="ssh-add ~/.ssh/id_ed25519        # 将私钥添加到agent"
  ["ssh|启动agent"]="eval \$(ssh-agent -s)                  # 启动ssh-agent进程"

  # Linux 基础（主题：linux）
  ["linux|查看进程"]="ps -ef | grep 进程名                  # 过滤查看指定进程"
  ["linux|终止进程"]="kill -9 PID                           # 强制终止指定PID进程"
  ["linux|查看磁盘"]="df -h                                 # 人性化显示磁盘占用"
  ["linux|查看目录大小"]="du -sh 目录名                     # 查看目录总大小"

  # type -a 查询shell命令类型 (主题：type)
  ["type|查看shell命令类型"]="type_f_NAME()                 # 查看shell常见命令类型"

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

# ==================== 核心检索逻辑（适配Windows） ====================
helpInfo() {
  # 处理输入参数（主题 + 二次检索关键词）
  local search_topic="$1"
  local search_keyword="$2"

  # 第一步：无任何参数（仅查看可用主题）
  if [[ -z "$search_topic" ]]; then
    echo -e "$GREEN⁂ 可用命令主题 $delimiter$RESET"
    local all_topics=($(get_all_topics))
    for topic in "${all_topics[@]}"; do
      echo -e "  $BLUE$topic$RESET"
    done
    echo -e "\n使用示例：helpInfo git（查看Git命令） | help git clone（检索Git的clone命令）"
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
    echo -e "$RED⚠️  不存在该主题！$RESET"
    echo -e "$YELLOW⚠️  可用主题：$CYAN${all_topics[*]}$RESET"
    return 1
  fi

  # 第三步：检索指定主题的命令（无关键词显示全部，有关键词筛选）
  echo -e "$GREEN⁂ $search_topic 主题命令 $delimiter$RESET"
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
        echo -e "$BLUE→$RESET $desc"
        echo -e "  $GREEN$cmd$RESET\n"
        ((match_count++))
      fi
    fi
  done

  # 第四步：主题存在但无匹配关键词的提示
  if [[ $match_count -eq 0 && -n "$search_keyword" ]]; then
    echo -e "$RED⚠️  $search_topic 主题下未找到含「$search_keyword」的命令！$RESET"
    echo -e "该主题下所有命令：\n"
    # 重新打印该主题全部命令
    for key in "${!CMD_MANUAL[@]}"; do
      local topic="${key%%|*}"
      if [[ "$topic" == "$search_topic" ]]; then
        local desc="${key#*|}"
        local cmd="${CMD_MANUAL[$key]}"
        echo -e "$BLUE→$RESET $desc"
        echo -e "  $GREEN$cmd$RESET\n"
      fi
    done
  fi
}

# ==================== 定义要打印的配置字符串（转义特殊字符）====================
function type_f_NAME() {
    color_echo "YELLOW" "* type -f NAME"
    color_echo "YELLOW" "• type -f function while for in if else do then { } export exit cd source . : ["
    type -f function while for in if else do then { } export exit cd source . : [
}

gh_cli_prep="
# 1. 安装 GitHub CLI（gh）
# Windows Git Bash 可通过 scoop 安装：scoop install gh
# 或手动下载：https://github.com/cli/cli/releases

# 2. 登录 gh（关联 GitHub 账号，自动配置 SSH/HTTPS）
gh auth login
# 按提示选择：SSH → 生成新密钥 → 登录成功

# 3. 验证 gh 生效
gh auth status
"

ssh_key_cfg="
# 1. 生成 SSH 密钥（一路回车，无需设置密码）
ssh-keygen -t ed25519 -C \"你的GitHub邮箱@xxx.com\"

# 2. 启动 SSH 代理并添加密钥
eval \"\$(ssh-agent -s)\"
ssh-add ~/.ssh/id_ed25519  # 若生成时改了密钥名，替换为对应文件名

# 3. 复制公钥到剪贴板（Windows Git Bash）
cat ~/.ssh/id_ed25519.pub | clip

# 4. 网页端配置：GitHub → Settings → SSH and GPG keys → New SSH key → 粘贴公钥 → 保存
"

gh_flow="
# ==================== 1. 命令行 Fork 仓库（核心）====================
TARGET_REPO=\"原作者/仓库名\"  # 例：torvalds/linux
gh repo fork \$TARGET_REPO --clone=false  # Fork 到自己账号，不自动克隆

# ==================== 2. 克隆自己 Fork 的仓库（SSH 方式）====================
git clone git@github.com:\$(gh api user | jq -r .login)/\${TARGET_REPO#*/}.git
cd \${TARGET_REPO#*/}

# ==================== 3. 关联原仓库（同步更新用）====================
git remote add upstream git@github.com:\$TARGET_REPO.git

# ==================== 4. 新建并切换开发分支 ====================
BRANCH_NAME=\"feature/add-rainbow\"
git checkout -b \$BRANCH_NAME

# ==================== 5. 编码+提交代码 ====================
# 【此处手动编写代码】
git add .
git commit -m \"feat: 新增彩虹色闪烁功能\"
git push origin \$BRANCH_NAME

# ==================== 6. 命令行发起 PR ====================
gh pr create \
  --base main \          # 原仓库目标分支
  --head \$BRANCH_NAME \  # 自己的开发分支
  --title \"新增彩虹色闪烁功能\" \
  --body \"适配 Git Bash，解决闪烁样式残留问题\"

# ==================== 7. 代码评审（网页端/命令行均可）====================
# 命令行查看 PR 评论
gh pr reviews

# 若需修改代码，提交后重新推送（PR 自动更新）
# git add . && git commit -m \"fix: 修复XX问题\" && git push origin \$BRANCH_NAME

# ==================== 8. 合并后同步（PR 被合并后执行）====================
git checkout main
git pull upstream main  # 同步原仓库最新代码
git push origin main    # 更新自己的 Fork 仓库
git branch -d \$BRANCH_NAME  # 删除本地开发分支
"

# 自定义函数helpInfo: 打印帮助信息
function github_steps() { # show the steps for developing in github
    color_echo "PURPLE" "$delimiter"
    color_echo "BLUE" "github CLI下载: ${gh_cli_prep}"
    color_echo "PURPLE" "$delimiter"
    color_echo "CYAN" "配置密钥（仅首次需要）: ${ssh_key_cfg}"
    color_echo "PURPLE" "$delimiter"
    color_echo "WHITE" "${gh_flow}"
    color_echo "PURPLE" "$delimiter"
    color_echo "WHITE" "github代码开发步骤 = 配置密钥 → Fork → 分支 → 编码 → PR → Review → 合并"
    color_echo "PURPLE" "$delimiter"
}

# 暴露命令到全局
export -f helpInfo
