# MyDevEnv
个人云端环境基准库

# 第一步 安装Git（若未安装）
winget install Git.Git -y
# 克隆你的云端仓库 (SSH方式连接)
git clone git@github.com:SingleHouston/MyDevEnv.git

# 第二步 安装环境配置
cd D:\gitHub\MyDevEnv
.\Install-MyEnv.ps1

# 第三步 更新仓库配置并配置本地环境~/.bashrc
git pull # alias gpl="git pull"
cp .bashrc ~/.bashrc # alias c="cp .bashrc ~/.bashrc"

# 第四步 为不同的环境配置vscode插件
|-- HTML_For_VsCode.md
|-- Python_For_VsCode.md
|-- STM32CubeIDE_For_VsCode.md
