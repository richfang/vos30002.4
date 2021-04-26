# linux
CentOS7.*换CentOS6.8系统:
<br />wget https://raw.githubusercontent.com/279192434/linux/main/CentOSNET.sh && chmod 777 CentOSNET.sh
<br />bash CentOSNET.sh -c 6.8 -v 64 -a --mirror 'http://mirrors.aliyun.com/centos-vault/'
<br />默认用户：root 密码：Vicer
<br />更新源：
<br />wget https://raw.githubusercontent.com/279192434/linux/main/yum-update.sh && chmod 777 yum-update.sh && bash yum-update.sh
<br />下载vos30002140安装包wget https://media.githubusercontent.com/media/279192434/linux/main/vos30002140.tar.gz
<br />解压tar xf vos30002140.tar.gz
<br />安装内核文件
<br />cd vos30002140 && chmod 777 * && ./install6.sh执行完服务器会自动重启
<br />安装vos30002140系统
<br />cd vos30002140 && ./install.sh
