#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[uninstall keepalived script path]:" $script_path
pkg_path=pkg
cd $pkg_path



#function uninstall_keepalived(){
#  kpstate=$(systemctl status keepalived | grep -v grep | grep "active (running)" |wc -l)
#  echo "【keepalived 状态(0-不活跃；非0-活跃)】:" ${kpstate}
#  if [ "${kpstate}" -ne 0 ]; then
#    echo "keepalived has installed...delete!"
#    #  停止服务
#    systemctl stop keepalived && systemctl status keepalived
#  fi
#
#  # 源码所在目录
#  # cd /opt/keepalived-1.3.5
#  keepalived_bin_path=$(which keepalived)
#  echo "【keepalived_bin_path】:" ${keepalived_bin_path}
#  result=$(echo $keepalived_bin_path | grep "/usr/bin/which: no")
#  if [[ "$result" = "" ]]; then
#   # 执行卸载
#   echo "make uninstall keepalived "
#   make uninstall
#  fi
#  #删除相关文件
#  rm -f /usr/local/sbin/keepalived
#  rm -f /usr/local/etc/rc.d/init.d/keepalived
#  rm -f /usr/local/etc/sysconfig/keepalived
#  rm -rf /usr/local/etc/keepalived
#  rm -f /usr/local/bin/genhash
#  # 删除配置信息
#  rm -rf  /etc/sysconfig/keepalived
#  rm -rf /usr/sbin/keepalived
#  rm -rf /etc/init.d/keepalived
#  rm -rf /lib/systemd/system/keepalived.service
#  rm -rf /etc/keepalived
#  rm -rf /etc/vip
#  # 删除配置信息
#  rm -rf /opt/keepalived-1.3.5
#  rm -rf /usr/local/keepalived
#
#}

function remove_keepalived_config(){
#    # 1. 删除监控脚本 check_pg.sh
#    rm -rf /etc/keepalived/check_pg.sh
#
#    # 2. 删除keepalived配置文件
#    rm -rf /etc/keepalived/keepalived.conf

    # 3. 删除监控脚本 check_keepalived.sh
    rm -rf /etc/vip/check_vip.sh
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

  systemctl restart crond.service
}

 # 执行
#uninstall_keepalived
#remove_keepalived_config
set_cron
