#!/bin/bash

#  Exit immediately if any untested command fails
set -o errexit


# install params
prop_path=./install.properties
source $prop_path



if [ true = "${HA_HARBOR_FLAG}" ];then

  echo " [0/3] 高可用Harbor安装参数校验 "
  echo "HA Harbor Example:: sh install_sothisai_harbor.sh  MASTER_HARBOR_IP  OR BACKUP_HARBOR_IP OR HARBOR_VIP OR HARBOR_DATA_PATH"
  echo "HA Harbor Example: sh /opt/ai/install_sothisai_harbor.sh 10.6.6.213 10.6.6.214  10.6.6.215 /harbordata "
  if [[  -z ${MASTER_HARBOR_IP}  || -z ${BACKUP_HARBOR_IP}   || -z ${HARBOR_VIP} || -z ${HARBOR_DATA_PATH}  ]]; then
    echo "MASTER_HARBOR_IP  OR BACKUP_HARBOR_IP OR HARBOR_VIP OR HARBOR_DATA_PATH is missing"
    exit
  fi
else
  echo " [0/3] 单机参数校验 "
  echo "Single Harbor Example:: sh install_sothisai_harbor.sh SCRIPT_PATH OR MASTER_HARBOR_IP "
  echo "Single Harbor Example: sh /fly/harbor-ha-v2-20220717/install_sothisai_harbor.sh 10.0.41.156 5000"
  if [[  -z ${MASTER_HARBOR_IP} ]]; then
    echo "MASTER_HARBOR_IP  is missing"
    exit
  fi
fi


if [ true = "${HA_HARBOR_FLAG}" ] && [ ! -z "${BACKUP_HARBOR_IP}" ]; then
   # 备用节点 分发Harbor安装包
   echo " [0/3] 备用节点分发Harbor安装包 "
   # harbor安装包
   HARBOR_TAR=harbor.tgz
   #prepare
   # 备用节点创建/tmp/harbor目录
   ssh ${BACKUP_HARBOR_IP} "rm -rf ${SCRIPT_PATH} ; mkdir -p ${SCRIPT_PATH}"
   # harbor安装包打包分发
   #compress resource
   tar -zcvf /tmp/${HARBOR_TAR} -C ../harbor .
   #send tar to harbor node 备用节点
   scp /tmp/${HARBOR_TAR} ${BACKUP_HARBOR_IP}:${SCRIPT_PATH}
   # 解压包
   ssh ${BACKUP_HARBOR_IP} "cd ${SCRIPT_PATH} && tar -zxvf ${SCRIPT_PATH}/${HARBOR_TAR} -C ${SCRIPT_PATH} "


    # 2. 部署PG主从复制集群
    #pg角色
    # pg-0(pg主节点)/pg-1(pg备节点)
    echo " [1/3] 开始部署PG主从复制集群 "

    echo " [1/3] 开始部署PG主从复制集群-主节点 "
    # 部署命令
    ssh ${MASTER_HARBOR_IP} "sh ${SCRIPT_PATH}/1-pg/install_pg.sh pg-0 ${MASTER_HARBOR_IP}" 2>&1
    if [ $? -eq 0 ];then
          echo " 主节点-成功安装PG! "
        else
          echo " 主节点-失败安装PG!"
          exit 2
    fi

    echo " [1/3] 开始部署PG主从复制集群-备节点 "
    # 部署命令
    ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/1-pg/install_pg.sh pg-1 ${MASTER_HARBOR_IP}" 2>&1
    if [ $? -eq 0 ];then
          echo " 备节点-成功安装PG! "
        else
          echo " 备节点-失败安装PG!"
          exit 2
    fi

    echo " [1/3] 成功部署PG主从复制集群 "

fi
