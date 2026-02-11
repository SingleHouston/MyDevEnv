alias make='mingw32-make'
export PATH=/d/Tools/ARM_GCC/bin/:/d/msys64/usr/bin:/d/msys64/mingw64/bin:$PATH
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
cd /d/gitHub/MyDevEnv
cp -f ~/.bashrc ./
git status
