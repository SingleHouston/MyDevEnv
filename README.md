# MyDevEnv
个人云端环境基准库

# 第一步 安装Git（若未安装）
winget install Git.Git -y
# 克隆你的云端仓库（替换为你的仓库地址）
git clone https://gitee.com/你的用户名/MyDevEnv.git D:\gitHub\MyDevEnv

# 第二步 安装环境配置
cd D:\gitHub\MyDevEnv
.\Install-MyEnv.ps1

# 第三步 配置~/.bashrc
cp .bashrc ~/.bashrc

# 第四步 为不同的环境配置vscode插件
|-- HTML_For_VsCode.md
|-- Python_For_VsCode.md
|-- STM32CubeIDE_For_VsCode.md
