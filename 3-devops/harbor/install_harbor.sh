#!/bin/bash

#  Exit immediately if any untested command fails
set -o errexit


# install params
prop_path=./install.properties
source $prop_path



if [ true = "${HA_HARBOR_FLAG}" ];then

  echo " [0/3] 高可用Harbor安装参数校验 "
  echo "HA Harbor Example:: sh install_sothisai_harbor.sh  MASTER_HARBOR_IP  OR BACKUP_HARBOR_IP OR HARBOR_VIP OR HARBOR_DATA_PATH"
  echo "HA Harbor Example: sh /opt/ai/install_sothisai_harbor.sh 10.6.6.213  10.6.6.214  10.6.6.215 /harbordata "
  if [[  -z ${MASTER_HARBOR_IP}  || -z ${BACKUP_HARBOR_IP}  ||  -z ${HARBOR_VIP} || -z ${HARBOR_DATA_PATH}  ]]; then
    echo "MASTER_HARBOR_IP  OR BACKUP_HARBOR_IP  OR HARBOR_VIP OR HARBOR_DATA_PATH is missing"
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

    echo " [1/3] 已经部署PG主从复制集群 "


    # 3. 添加keepalived检测脚本
    #keepalived角色
    # MASTER(主节点)/BACKUP(pg备节点)
    echo " [2/3] 开始添加keepalived检测脚本 "
    echo " [2/3] 开始添加keepalived检测脚本-主节点 "
    # 部署命令
    sh ./2-keepalived/install_keepalived.sh ${HARBOR_VIP}
    if [ $? -eq 0 ];then
          echo " 主节点-成功添加keepalived检测脚本! "
        else
          echo " 主节点-失败添加keepalived检测脚本!"
          exit 2
    fi

    echo " [3/4] 开始添加keepalived检测脚本-备节点 "
    # 部署命令
    ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/2-keepalived/install_keepalived.sh ${HARBOR_VIP}" 2>&1
    if [ $? -eq 0 ];then
          echo " 备节点-成功添加keepalived检测脚本! "
        else
          echo " 备节点-失败添加keepalived检测脚本!"
          exit 2
    fi

    echo " [2/3] 成功添加keepalived检测脚本 "
else

  echo " [1/3] 单机无需部署PG主从复制集群 "
  echo " [2/3] 单机无需添加keepalived检测脚本 "

fi



# 4. 安装docker-compose 和harbor(离线)
echo " [3/3] 开始安装docker-compose和harbor "

# 是否重新生成证书（即：使用已经生成的证书，还是重新生成）
if [ true = "${USE_HARBOR_HTTPS}" ];then

  # 1. 提供的证书不存在 不可用才走下面的逻辑 crt和key 是harbor要使用的，cert和key是docker使用的，ca.crt是根证书
  if [ ! -f "${CERT_GEN_PATH}/${DOMAIN_NAME}.crt" ] || [ ! -f "${CERT_GEN_PATH}/${DOMAIN_NAME}.key" ] \
     || [ ! -f "${CERT_GEN_PATH}/${DOMAIN_NAME}.cert" ] || [ ! -f "${CERT_GEN_PATH}/ca.crt" ] ;then

        if [ true = "${HA_HARBOR_FLAG}" ];then
           # 高可用
           echo " 高可用Harbor生成CA证书/HARBOR证书/DOCKER客户端证书! "
           sh ${SCRIPT_PATH}/4-util/ssl/gen_harbor_cert.sh ${HARBOR_VIP} ${DOMAIN_NAME} ${CERT_GEN_PATH}
           if [ $? -eq 0 ];then
                 echo " 高可用Harbor成功生成CA证书/HARBOR证书/DOCKER客户端证书! "
               else
                 echo " 高可用Harbor失败生成CA证书/HARBOR证书/DOCKER客户端证书!"
                 exit 2
           fi

        else
           # 单机
           echo " 单机Harbor生成CA证书/HARBOR证书/DOCKER客户端证书! "
           sh ${SCRIPT_PATH}/4-util/ssl/gen_harbor_cert.sh  ${MASTER_HARBOR_IP} ${DOMAIN_NAME} ${CERT_GEN_PATH}
           if [ $? -eq 0 ];then
                 echo " 单机Harbor成功生成CA证书/HARBOR证书/DOCKER客户端证书! "
               else
                 echo " 单机Harbor失败生成CA证书/HARBOR证书/DOCKER客户端证书!"
                 exit 2
           fi

        fi
  fi

  # 2. 域名映射 / 向备用节点分发证书
  if [ true = "${HA_HARBOR_FLAG}" ];then
      # 域名映射 / 向备用节点分发证书
      echo " 高可用Harbor,添加域名映射 / 向备用节点分发证书 ! "
      sh ${SCRIPT_PATH}/4-util/ssl/update_harbor_ssl.sh ${DOMAIN_NAME} ${HARBOR_VIP} ${CERT_GEN_PATH} ${MASTER_HARBOR_IP} ${BACKUP_HARBOR_IP}
    else
       # 域名映射
       echo " 单机Harbor,添加域名映射 ! "
       sh ${SCRIPT_PATH}/4-util/ssl/update_harbor_ssl.sh  ${DOMAIN_NAME} ${MASTER_HARBOR_IP} ${CERT_GEN_PATH} ${MASTER_HARBOR_IP}

  fi

fi

echo " [3/3] 开始安装docker-compose和harbor-单机/主节点 "


if [ true = "${HA_HARBOR_FLAG}" ];then

  if [ true = "${USE_HARBOR_HTTPS}" ];then
     # 高可用部署命令[https]
     sh ./3-harbor/install_ha_harbor.sh ${MASTER_HARBOR_IP} ${HARBOR_NETWORK_CIDR} ${HARBOR_VIP} ${HARBOR_DATA_PATH} ${DOMAIN_NAME} ${CERT_GEN_PATH}

  else
    # 高可用部署命令[http]
    sh ./3-harbor/install_ha_harbor.sh ${MASTER_HARBOR_IP} ${HARBOR_NETWORK_CIDR}  ${HARBOR_VIP} ${HARBOR_DATA_PATH}

  fi

else

  if [ true = "${USE_HARBOR_HTTPS}" ];then
     # 单机部署命令[https]
     sh ./3-harbor/install_single_harbor.sh ${MASTER_HARBOR_IP} ${HARBOR_NETWORK_CIDR} ${HARBOR_DATA_PATH} ${DOMAIN_NAME} ${CERT_GEN_PATH}
  else
     # 单机部署命令[http]
     sh ./3-harbor/install_single_harbor.sh ${MASTER_HARBOR_IP} ${HARBOR_NETWORK_CIDR} ${HARBOR_DATA_PATH}
  fi

fi


if [ $? -eq 0 ];then
      echo " 主节点-成功安装docker-compose和harbor! "
    else
      echo " 主节点-失败安装docker-compose和harbor!"
      exit 2
fi


# 如果有备用节点
if [ "true" == "${HA_HARBOR_FLAG}" ] && [ ! -z "${BACKUP_HARBOR_IP}" ]; then

  echo " [3/3] 开始安装docker-compose和harbor-备节点 "

    if [ true = ${USE_HARBOR_HTTPS} ];then
       # 高可用部署命令[https]
       ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/3-harbor/install_ha_harbor.sh ${BACKUP_HARBOR_IP} ${HARBOR_NETWORK_CIDR} ${HARBOR_VIP} ${HARBOR_DATA_PATH} ${DOMAIN_NAME} ${CERT_GEN_PATH}" 2>&1

    else
      # 高可用部署命令[http]
       ssh ${BACKUP_HARBOR_IP} "sh ${SCRIPT_PATH}/3-harbor/install_ha_harbor.sh ${BACKUP_HARBOR_IP} ${HARBOR_NETWORK_CIDR} ${HARBOR_VIP} ${HARBOR_DATA_PATH}" 2>&1

    fi


  if [ $? -eq 0 ];then
        echo " 备节点-成功安装docker-compose和harbor! "
      else
        echo " 备节点-失败安装docker-compose和harbor!"
        exit 2
  fi
fi

echo " [3/3] 成功安装docker-compose和harbor "
