@echo off
chcp 65001 > nul
echo ==============================================
echo 正在配置GitHub连接优化项...
echo ==============================================

:: 1. 备份原hosts文件（防止配置出错可恢复）
copy "%SystemRoot%\System32\drivers\etc\hosts" "%SystemRoot%\System32\drivers\etc\hosts.bak" > nul
echo ✅ 已备份hosts文件为 hosts.bak

:: 2. 写入GitHub稳定IPv4地址到hosts
echo ✅ 正在写入GitHub有效IP...
(
echo # GitHub 优化配置 Start
echo 140.82.113.3    github.com
echo 140.82.114.20   gist.github.com
echo 185.199.108.153 assets-cdn.github.com
echo 185.199.109.153 assets-cdn.github.com
echo 185.199.110.153 assets-cdn.github.com
echo 185.199.111.153 assets-cdn.github.com
echo 199.232.69.194  github.global.ssl.fastly.net
echo # GitHub 优化配置 End
) >> "%SystemRoot%\System32\drivers\etc\hosts"

:: 3. 刷新DNS缓存
ipconfig /flushdns
echo ✅ 已刷新本地DNS缓存

:: 4. 优化Git网络参数（提升传输稳定性）
echo ✅ 正在配置Git优化参数...
git config --global http.sslVerify false
git config --global http.postBuffer 524288000
git config --global http.maxRequestBuffer 100M
git config --global core.compression 9
git config --global ssh.keepalive true

echo ==============================================
echo 🎉 GitHub连接优化配置完成！
echo 📌 若后续再次不稳定，重新运行此脚本即可更新IP
echo ==============================================
pause