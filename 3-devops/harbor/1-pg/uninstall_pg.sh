#!/bin/bash
#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[uninstall pg script path]:" $script_path
pkg_path=pkg
cd $pkg_path


# 0. 参数校验
echo "please execute the script in the following format,case: sh uninstall_pg.sh Node_Role[pg-0(pg主节点)/pg-1(pg备节点)]"
# 创建时的节点角色（pg-0为主，pg-1为备）
Node_Role=$1

if [ -z $1 ]; then
	echo " Node_Role OR Master_Ip is missing"
	echo "please execute the script in the following format,case: sh uninstall_pg.sh Node_Role[pg-0(pg主节点)/pg-1(pg备节点)]"
	echo "Example: sh uninstall_pg.sh pg-0"
	exit
fi

# docker swarm
## 如果是pg-0(pg主节点)
if [ "pg-0" = "${Node_Role}" ];then
   echo "从节点-解散Swarm集群"
   ## 1. 主节点-删除`Down`从节点
   docker node ls | grep Down | awk '{print $1}' | xargs -t docker node rm
   ## 2. 主节点-删除网络
   docker network ls | grep sharednet | awk '{print $1}' | xargs -t docker network rm
   docker network ls | grep docker_gwbridge | awk '{print $1}' | xargs -t docker network rm
   # 3. 主节点-管理节点，解散集群
   docker swarm leave --force
  # 如果是pg-1(pg备节点)
  elif [ "pg-1" = "${Node_Role}" ];then
       echo "从节点-离开Swarm集群"
       docker swarm leave
fi


# set start-pg crontab
function set_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'start-pg'
  then
    echo "start-pg crontab task has added... delete"
    sed -i '/start-pg/d' /etc/crontab
  fi

  systemctl restart crond.service
}


# 1. 删除容器名为 pg-0（主）或者 pg-1（从）
docker rm -f ${Node_Role}
sleep 10

# 2. 创建存储和配置文件目录
rm -rf /opt/pgsql/bitnami/postgresql
rm -rf /opt/pgsql/custom-conf

# 3. pg启动
rm -rf /opt/pgsql/start-pg.sh

# 4. 删除PG镜像
docker rmi -f bitnami/postgresql-repmgr:9.6.21
# 5. set start-pg crontab
set_cron