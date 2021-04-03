#!/bin/bash
#中文-UTF8

#关闭源配置
sed -i 's/enabled=1/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf

#删除源文件
rm -rf /etc/yum.repos.d/*

#阿里云centos6源
tee /etc/yum.repos.d/CentOS-Base.repo <<-'EOF'
[base]
name=CentOS-6.10 - Base - http://mirrors.aliyun.com/centos-vault/
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos-vault/6.10/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos-vault/RPM-GPG-KEY-CentOS-6
EOF

# #国外官方centos6源
# tee /etc/yum.repos.d/CentOS-Base.repo <<-'EOF'
# [base]
# name=CentOS-6.10 - Base - vault.centos.org
# failovermethod=priority
# baseurl=http://vault.centos.org/6.10/os/$basearch/
# gpgcheck=1
# gpgkey=http://vault.centos.org/RPM-GPG-KEY-CentOS-6
# EOF

# #国内centos6私有源
# wget -O /etc/yum.repos.d/CentOS-Base.repo  http://yum.5cym.cn/Centos-6.repo

yum clean all
yum makecache