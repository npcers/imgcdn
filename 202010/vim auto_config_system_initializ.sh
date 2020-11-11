#!/bin/bash
#2017-5-20 13:14:00
#Author blog:
#https://www.yangxingzhen.com
#Author site:
#https://www.yangxingzhen.com/sitemap.html
#Author mirrors site:
# https://mirrors.yangxingzhen.com
#About the Author
#BY：、、、小柒
#QQ：675583110
#Automatic configuration system initialization
SYS_VERSION=`awk -F. '{print $1}' /etc/redhat-release |awk '{print $NF}'`
YUM_SOFT="vim wget lrzsz openssh-server openssh ntp ntpdate gcc gcc-c++ cmake unzip make curl openssl openssl-devel rsync gd zip perl sysstat man mtr lsof iotop net-tools openssl-perl iostat subversion nscd iotop htop iftop"
#Configuring the YUM source
if [ $SYS_VERSION -eq 7 ];then
    yum -y install wget
    mkdir -p /etc/yum.repos.d/back
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/back
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
    yum clean all
else
    yum -y install wget
    mkdir -p /etc/yum.repos.d/back
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/back
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo
    yum clean all
fi
#install base rpm package
yum -y install epel-release
yum -y install $YUM_SOFT
#Change the ulimit parameter
\cp /etc/security/limits.conf /etc/security/limits.conf.back
cat >>/etc/security/limits.conf <<EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
echo "ulimit -SHn 65535" >> /etc/profile
echo "ulimit -SHn 65535" >> /etc/rc.local
#Time zone
if [ "`cat /etc/crontab | grep ntpdate`" = "" ]; then
echo "10 * * * * root /usr/sbin/ntpdate cn.pool.ntp.org >> /var/log/ntpdate.log" >> /etc/crontab
fi
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
ntpdate cn.pool.ntp.org && hwclock -w
#Config SSH
sed -i "s/\#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/g" /etc/ssh/sshd_config
#Config Selinux And iptables(firewalld)
if [ $SYS_VERSION -eq 7 ];then
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    sed -i '/SELINUX/s/enforcing/disabled/g' /etc/selinux/config
    setenforce 0
else
    service iptables stop
    chkconfig iptables off
    sed -i '/SELINUX/s/enforcing/disabled/g' /etc/selinux/config
    setenforce 0
fi
#Config sysctl
SYSCONF="net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_fin_timeout = 120
net.ipv4.tcp_keepalive_time = 120
net.ipv4.ip_local_port_range = 1024 65535
net.nf_conntrack_max = 16404388
net.netfilter.nf_conntrack_tcp_timeout_established = 10800
#kernel: TCP: time wait bucket table overflow
net.ipv4.tcp_max_tw_buckets = 30000
fs.file-max = 655350
kernel.sysrq = 0"
if [ $SYS_VERSION -eq 6 ];then
    service sshd restart
    if [ `cat /etc/sysctl.conf | grep -wc net.ipv4.tcp_max_tw_buckets` -eq 0 ];then
        echo "$SYSCONF" >>/etc/sysctl.conf
        /sbin/sysctl -p
    fi
else
    systemctl restart sshd.service
    if [ ! -f /etc/sysctl.d/system.conf ];then
        touch /etc/sysctl.d/system.conf
        echo "$SYSCONF" >>/etc/sysctl.d/system.conf
        /usr/sbin/sysctl -p
    fi
fi
if [ $? -eq 0 ];then
    echo -e "\033[32m Completion of system initialization \033[0m"
fi