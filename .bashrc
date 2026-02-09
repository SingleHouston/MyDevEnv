alias make='mingw32-make'
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:$PATH
delimiter="------------------------------------------------------------------------------------"
echo $delimiter
python --version;echo $delimiter
gcc --version;echo $delimiter
arm-none-eabi-gcc --version;echo $delimiter
git --version;echo $delimiter
# 打开 GitHub 网页
github
explorer.exe https://github.com
cd /d/gitHub/MyDevEnv
cp -f ~/.bashrc ./
git status
