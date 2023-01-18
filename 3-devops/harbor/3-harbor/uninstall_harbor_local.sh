#!/bin/bash

echo "Uninstall harbor"
#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install harbor-single script path]:" $script_path
pkg_path=pkg
cd $pkg_path

# set check_harbor crontab
function set_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'check_harbor'
  then
    echo "check_harbor crontab task has added... delete"
    sed -i '/check_harbor/d' /etc/crontab
    systemctl restart crond.service
  fi

  if [ -f "/etc/vip/check_harbor.sh" ];then
    rm -rf /etc/vip/check_harbor.sh
  fi
}

echo "-----[0/6]start uninstall harbor on node `hostname`"
# 1. 卸载harbor
echo "-----[1/6]stop and remove harbor resources on node `hostname`"
docker-compose -f /opt/harbor/docker-compose.yml down
sleep 50

# Harbor 状态
harborState=$(docker-compose  -f /opt/harbor/docker-compose.yml ps | wc -l)
echo "【Harbor 状态(非0-组件都没有启动；0-组件都没有启动)】:" ${harborState}
if [ "${harborState}" -ne 0 ]; then
  for i in `docker ps | grep harbor |awk '{print $1}'`;do docker rm -f $i;done
  docker-compose -f /opt/harbor/docker-compose.yml down
fi

# 2. 清理无用的镜像和容器
echo "-----[2/6]cleanup unuseful image or container on node `hostname`"
docker images | grep goharbor | awk '{print $3}' | xargs docker rmi -f

# 3. 卸载harbor安装包 和 镜像数据
echo "-----[3/6]uninstall harbor package  on node `hostname`"
rm -rf /opt/harbor/


# 4. 卸载docker-compose
#echo "-----[4/6] retain docker-compose on node `hostname`"
echo "-----[4/6]uninstall docker-compose on node ${LOCAL_IP}"
rm -rf /usr/local/bin/docker-compose
rm -rf /usr/local/sbin/docker-compose

# 卸载 harbor系统服务
sh ./system_servie/unconfig_harbor_systemd_service.sh

# 是否存在harbor网桥
harbor_network=`docker network ls | grep harbor | awk '{print $1}'`
if [ ! -z "${harbor_network}" ]; then
  docker network ls | grep harbor | awk '{print $1}' | xargs -t docker network rm
fi

## 5. 根据条件判断 是否 卸载harbor镜像数据
echo "-----[5/6] retain harbor data on node `hostname`"
#if [[ -n "${DATA_VOLUME}" ]]; then
#  echo "-----[5/6] remove harbor data on node `hostname`"
#  # 卸载harbor镜像数据
#  rm -rf ${DATA_VOLUME}
#else
#  echo "-----[5/6] retain harbor data on node `hostname`"
#fi

# 6. 高可用 清理监控脚本 check_harbor.sh
echo "-----[6/6]remove check_harbor.sh(/etc/crontab) on node ${LOCAL_IP}"
set_cron


