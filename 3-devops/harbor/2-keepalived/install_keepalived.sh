#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install pg script path]:" $script_path
pkg_path=pkg
cd $pkg_path
conf_path=`pwd`

##check param
#if [[ -z $1 || -z $2 || -z $3 ]]; then
#	echo " ROLE OR VIP OR Interface_Name is missing"
#	echo "please execute the script in the following format,case: sh install_keepalived.sh ROLE VIP Interface_Name"
#	echo "Example: sh install_keepalived.sh BACKUP 10.13.3.205 ens192 "
#	exit
#fi
#
## keepalived 角色 MASTER主机还是备用机BACKUP
#ROLE=$1
## VIP
#VIP=$2
## 实例绑定的网卡
#Interface_Name=$3

# VIP
VIP=$1


#function install_keepalived(){
#  kpstate=$(systemctl status keepalived | grep -v grep | grep "active (running)" |wc -l)
#  echo "【keepalived 状态(0-不活跃；非0-活跃)】:" ${kpstate}
#  if [ "${kpstate}" -ne 0 ]; then
#    echo "keepalived has installed...delete!"
#    #  停止服务
#    systemctl stop keepalived && systemctl status keepalived
#
#    # 源码所在目录
#    # cd /opt/keepalived-1.3.5
#    keepalived_bin_path=$(which keepalived)
#    echo "【keepalived_bin_path】:" ${keepalived_bin_path}
#    result=$(echo $keepalived_bin_path | grep "/usr/bin/which: no")
#    if [[ "$result" = "" ]]; then
#     # 执行卸载
#     echo "make uninstall keepalived "
#     make uninstall
#    fi
#
#    #删除相关文件
#    rm -f /usr/local/sbin/keepalived
#    rm -f /usr/local/etc/rc.d/init.d/keepalived
#    rm -f /usr/local/etc/sysconfig/keepalived
#    rm -rf /usr/local/etc/keepalived
#    rm -f /usr/local/bin/genhash
#    # 删除配置信息
#    rm -rf  /etc/sysconfig/keepalived
#    rm -rf /usr/sbin/keepalived
#    rm -rf /etc/init.d/keepalived
#    rm -rf /lib/systemd/system/keepalived.service
#    rm -rf /etc/keepalived
#    rm -rf /etc/vip
#    # 删除配置信息
#    rm -rf /opt/keepalived-1.3.5
#    rm -rf /usr/local/keepalived
#  fi
#
#    # 1. 安装依赖包
#    echo "安装依赖包..."
#    rpm -Uvh --force --nodeps ./gcc/*rpm
#    rpm -Uvh --force --nodeps ./openssl-devel/*rpm
#    rpm -Uvh --force --nodeps ./libnl/*rpm
#
#    echo "开始编译安装keepalived..."
#    sleep 1
#
#
#    # 2. 编译安装
#    tar -xzvf keepalived-1.3.5.tar.gz -C  /opt
#    cd /opt/keepalived-1.3.5
#    ./configure --prefix=/usr/local/keepalived --with-openssl=/opt/openssl-1.0.2l
#    make && make install
#    echo "keepalived安装成功，设置启动项..."
#    sleep 1
#
#    # 3. 启动设置：
#    cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
#    cp /usr/local/keepalived/sbin/keepalived /usr/sbin/keepalived
#    # 注册为系统服务
#    cp keepalived/etc/init.d/keepalived /etc/init.d/keepalived
#    # 开机启动：
#    chkconfig keepalived on
#    # 修改PIDFile避免启动报错
#    sed -i 's?/usr/local/keepalived??' /lib/systemd/system/keepalived.service
#
#    # 3. 重启
#    systemctl daemon-reload
#    systemctl start keepalived && systemctl status keepalived
#    if [ $? -eq 0 ];then
#      echo " Install keepalived-1.3.5 Successfully!"
#    else
#      echo " Install keepalived-1.3.5 Failed!"
#    fi
#
#}

function update_keepalived(){
#    echo " Update Keepalived Conf!"
#    # 1.对主从PG状态进行监控，监控脚本 check_pg.sh
#    mkdir /etc/keepalived
#    cp ${conf_path}/check_pg.sh /etc/keepalived/check_pg.sh
#    sed -i "s/1.1.1.1/$VIP/g" /etc/keepalived/check_pg.sh
#    chmod 755 /etc/keepalived/check_pg.sh
#    # 2. keepalived配置文件
#    cp ${conf_path}/keepalived.conf /etc/keepalived/keepalived.conf
#    # 更新替换状态是MASTER主机还是备用机BACKUP
#
#    # 设置优先级
#    # keepalived 角色 MASTER主机还是备用机BACKUP
#    if [ "MASTER" = "${ROLE}" ];then
#      sed -i "s/PRIORITY_NUMBER/100/g" /etc/keepalived/keepalived.conf
#      # 如果是pg-1(pg备节点)
#      elif [ "BACKUP" = "${ROLE}" ];then
#         sed -i "s/PRIORITY_NUMBER/70/g" /etc/keepalived/keepalived.conf
#    fi
#
#    # 更新替换VIP
#    sed -i "s/1.1.1.1/$VIP/g" /etc/keepalived/keepalived.conf
#    sed -i "s/Interface_Name/$Interface_Name/g" /etc/keepalived/keepalived.conf

    # 3. 对keepalived状态进行监控，监控脚本 check_keepalived.sh
    mkdir /etc/vip
    cp ${conf_path}/vip/check_vip.sh /etc/vip/check_vip.sh
    sed -i "s/1.1.1.1/$VIP/g" /etc/vip/check_vip.sh
    chmod 755 /etc/vip/check_vip.sh

#    systemctl daemon-reload
#    systemctl restart keepalived && systemctl status keepalived
#    if [ $? -eq 0 ];then
#      echo " Update keepalived-1.3.5 Successfully!"
#    else
#      echo " Update keepalived-1.3.5 Failed!"
#    fi
}


# set check_vip crontab
function set_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'check_vip'
  then
    echo "check_vip crontab task has added... delete"
    sed -i '/check_vip/d' /etc/crontab
  fi

  # echo "* * * * * root /etc/vip/check_vip.sh">>/etc/crontab
  echo "*/1 * * * * root sleep 39; sh /etc/vip/check_vip.sh">>/etc/crontab

  systemctl restart crond.service
}

#install_keepalived
update_keepalived
set_cron
