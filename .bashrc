# Usual aliases
alias bash_ed='vim ~/.bashrc'
alias bash_src='source ~/.bashrc'
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
alias gr='git reset'
alias gs='git status'
# Exported variables
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:$PATH
# Show the usal utils' version in git-bash 
delimiter="------------------------------------------------------------------------------------"
echo $delimiter
cygpath -w $(which python);python --version;echo $delimiter
cygpath -w $(which gcc);gcc --version;echo $delimiter
cygpath -w $(which arm-none-eabi-gcc);arm-none-eabi-gcc --version;echo $delimiter
cygpath -w $(which git);git --version;echo $delimiter
echo "Usual websites:"
echo "explorer.exe https://github.com"
echo "explorer.exe https://test.ustc.edu.cn"
echo "explorer.exe https://www.yyzlab.com.cn/aiEliteJobClass/1957271757362696205"
echo $delimiter
# Show the md files in MyDevEnv
cd /d/gitHub/MyDevEnv
ls *.md -1;echo $delimiter
# Update the .bashrc from git-bash to see if anything changed
cp -f ~/.bashrc ./
git status
