#!/bin/bash


# install params
prop_path=./install.properties
source $prop_path
#check param

if [ true = ${HA_HARBOR_FLAG} ];then
   echo " [0/3] 高可用Harbor卸载参数校验 "
  #check param
  if [[  -z ${MASTER_HARBOR_IP} ||  -z ${BACKUP_HARBOR_IP}  ]]; then
    echo "MASTER_HARBOR_IP OR BACKUP_HARBOR_IP is missing"
    exit
  fi

else

  echo " [0/3] 单机Harbor卸载参数校验 "
  #check param
  if [[  -z ${MASTER_HARBOR_IP} ]]; then
  	echo "MASTER_HARBOR_IP  is missing"
  	exit
  fi

fi

# 格式转换
# 0. 格式转换 dos2unix


# 1. 卸载docker-compose 和harbor(离线)
echo " [1/3] 开始卸载docker-compose和harbor "

echo " [1/3] 开始卸载docker-compose和harbor-主节点 "

# 卸载命令
sh ./3-harbor/uninstall_harbor_local.sh
if [ $? -eq 0 ];then
      echo " 主节点-成功卸载docker-compose和harbor! "
    else
      echo " 主节点-失败卸载docker-compose和harbor!"
      exit 2
fi

# 如果有备用节点
if [ true = "${HA_HARBOR_FLAG}" ] && [ ! -z "${BACKUP_HARBOR_IP}" ]; then
  echo " [1/3] 开始卸载docker-compose和harbor-备节点 "

  # 卸载命令
  ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/3-harbor/uninstall_harbor_local.sh " 2>&1
  if [ $? -eq 0 ];then
        echo " 备节点-成功卸载docker-compose和harbor! "
      else
        echo " 备节点-失败卸载docker-compose和harbor!"
        exit 2
  fi
fi

echo " [1/3] 成功卸载docker-compose和harbor "



if [ true = ${HA_HARBOR_FLAG} ];then
  # 3. 卸载keepalived
  #keepalived角色
  # MASTER(主节点)/BACKUP(pg备节点)
  echo " [2/3] 开始卸卸载keepalived检测脚本 "
  echo " [2/3] 开始卸载keepalived检测脚本-主节点 "

  # 卸载命令
  sh ./2-keepalived/uninstall_keepalived.sh
  if [ $? -eq 0 ];then
        echo " 主节点-成功卸载keepalived检测脚本 "
      else
        echo " 主节点-失败卸载keepalived检测脚本"
        exit 2
  fi

  echo " [2/3] 开始卸载keepalived-备节点 "

  # 卸载命令
  ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/2-keepalived/uninstall_keepalived.sh" 2>&1
  if [ $? -eq 0 ];then
        echo " 备节点-成功卸载keepalived检测脚本 "
      else
        echo " 备节点-失败卸载keepalived检测脚本"
        exit 2
  fi

  echo " [2/3] 成功卸载keepalived "


  # 3. 卸载PG主从复制集群
  #pg角色
  # pg-0(pg主节点)/pg-1(pg备节点)
  echo " [3/3] 开始卸载PG主从复制集群 "
  echo " [3/3] 开始卸载PG主从复制集群-主节点 "


  # 卸载命令
  sh ./1-pg/uninstall_pg.sh pg-0
  if [ $? -eq 0 ];then
        echo " 主节点-成功卸载PG! "
      else
        echo " 主节点-失败卸载PG!"
        exit 2
  fi

  echo " [3/4] 开始卸载PG主从复制集群-备节点 "
  # 卸载命令
  ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/1-pg/uninstall_pg.sh pg-1" 2>&1
  if [ $? -eq 0 ];then
        echo " 备节点-成功卸载PG! "
      else
        echo " 备节点-失败卸载PG!"
        exit 2
  fi

  echo " [3/3] 成功卸载PG主从复制集群 "

else

  echo " [2/3] 单机无需卸载PG主从复制集群 "
  echo " [3/3] 单机无需卸载keepalived "

fi


# 4. 卸载docker(离线)

#if [ true = ${UNINSTALL_DOCKER} ];then
#  echo " [4/4] 开始卸载docker "

#  echo " [4/4] 主节点-开始卸载docker "


#  if [ $? -eq 0 ];then
#        echo " 主节点-成功卸载docker! "
#      else
#        echo " 主节点-失败卸载docker!"
#        exit 2
#  fi

#  # 如果有备用节点
#  if [ true = ${HA_HARBOR_FLAG} ] && [ ! -z ${BACKUP_HARBOR_IP} ]; then
#    echo " [4/4] 备节点-开始卸载docker "


#    if [ $? -eq 0 ];then
#          echo " 备节点-成功卸载docker! "
#        else
#          echo " 备节点-失败卸载docker!"
#          exit 2
#    fi
#    
#    echo " [4/4] 成功卸载docker "
#  fi
#else
#  echo " [4/4] 保留docker "
#fi
