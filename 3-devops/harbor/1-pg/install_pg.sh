#!/bin/bash
#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install pg script path]:" $script_path
pkg_path=pkg
cd $pkg_path


# 0. 参数校验
echo "please execute the script in the following format,case: sh install_pg.sh Node_Role[pg-0(pg主节点)/pg-1(pg备节点)] Master_Ip"
# 创建时的节点角色（pg-0为主，pg-1为备）
Node_Role=$1

## 主节点的IP
Master_Ip=$2

if [[ -z $1 || -z $2 ]]; then
	echo " Node_Role OR Master_Ip is missing"
	echo "please execute the script in the following format,case: sh install_pg.sh Node_Role[pg-0(pg主节点)/pg-1(pg备节点)] Master_Ip"
	echo "Example: sh install_pg.sh pg-0 10.13.3.11"
	exit
fi

# docker swarm
## 如果是pg-0(pg主节点)
if [ "pg-0" = "${Node_Role}" ];then
  ## 1. 主节点-初始化`Swarm`集群服务
  docker swarm init --advertise-addr=${Master_Ip}
  ## 2. 主节点-创建网络
  docker network create -d overlay --attachable sharednet
  ## 3. 主节点-查看网络
  docker network ls | grep sharednet
  # 如果是pg-1(pg备节点)
  elif [ "pg-1" = "${Node_Role}" ];then
      ## 1. 从节点-如果没有记住加入集群的`token`，以下可以重新获取*
      docker_swarm_join=`ssh ${Master_Ip} "docker swarm join-token worker" | grep -w "docker swarm join --token"`
      echo "从节点-加入Swarm集群：" ${docker_swarm_join}
      ## 2.从节点-加入`Swarm`集群
      ${docker_swarm_join}
fi

# 1. 创建存储和配置文件目录
mkdir -p /opt/pgsql/bitnami/postgresql
mkdir -p /opt/pgsql/custom-conf
chmod -R  777 /opt/pgsql/bitnami/postgresql
chmod -R  777 /opt/pgsql/custom-conf
# 2. pg启动
cp start-pg.sh /opt/pgsql/start-pg.sh
# 赋予执行权限
chmod 777 /opt/pgsql/start-pg.sh
# 导入PG镜像
docker load -i bitnami-postgresql-repmgr-9.6.21.tar

# set start-pg crontab
function set_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'start-pg'
  then
    echo "start-pg crontab task has added... delete"
    sed -i '/start-pg/d' /etc/crontab
  fi

  # echo "* * * * * root /opt/pgsql/start-pg.sh ${Node_Role}">>/etc/crontab
  # PG主节点再指定心跳间隔没有恢复正常才会降级为备用节点
  # 休息 100s，错开PG备节点变成主节点的过程（15*3s+10s左右数据同步）
  #  -- 也可以查看这个，主库是f代表false ；备库是t，代表true
  #  select pg_is_in_recovery();
  echo "* * * * * root sleep 57; /opt/pgsql/start-pg.sh ${Node_Role}">>/etc/crontab

  systemctl restart crond.service
}


# 3. 容器名为 pg-0（主）或者 pg-1（从）
/opt/pgsql/start-pg.sh ${Node_Role}

# 4. set start-pg crontab
set_cron