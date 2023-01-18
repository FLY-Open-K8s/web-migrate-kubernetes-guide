#!/bin/bash


echo "########################################################################################################## "
echo "Requirements : 镜像库节点和计算节点时间一致 "
echo "Single Harbor Example : sh update_harbor_ssl.sh DOMAIN_NAME MASTER_HARBOR_IP CERT_GEN_PATH MASTER_HARBOR_IP "
echo "Single Harbor Example : sh update_harbor_ssl.sh  image.ac.com  10.0.35.26 /data/cert 10.0.35.26"
echo "########################################################################################################## "
echo "HA Harbor Example: sh update_harbor_ssl.sh DOMAIN_NAME HARBOR_VIP CERT_GEN_PATH MASTER_HARBOR_IP HARBOR_BACK_IP"
echo "HA Harbor Example: sh update_harbor_ssl.sh image.ac.com 10.6.6.215 /harbordata/cert  10.6.6.213  10.6.6.214 "
echo "########################################################################################################## "

#check param
if [[ -z $1 || -z $2  || -z $3 ]]; then
	echo " DOMAIN_NAME  OR  DOMAIN_IP OR CERT_GEN_PATH is missing"
	exit
fi

# Harbor域名
DOMAIN_NAME=$1
# Harbor域名 对应的IP
DOMAIN_IP=$2
# 生成证书的路径
CERT_GEN_PATH=$3
# Harbor主IP
HARBOR_MASTER_IP=$4
# Harbor备IP
HARBOR_BACK_IP=$5



#echo " [STEP 1] 生成CA证书/HARBOR证书/DOCKER客户端证书 "
##sh gen_harbor_cert.sh ${HARBOR_MASTER_IP} ${DOMAIN_NAME} ${CERT_GEN_PATH} 2>&1
#if [ $? -eq 0 ];then
#      echo " [STEP 1] 成功生成CA证书/HARBOR证书/DOCKER客户端证书! "
#    else
#      echo " [STEP 1] 失败生成CA证书/HARBOR证书/DOCKER客户端证书!"
#      exit 2
#fi
#cd -
#echo " [STEP 1] 成功生成CA证书/HARBOR证书/DOCKER客户端证书 "

echo " [STEP 1] 成功生成CA证书/HARBOR证书/DOCKER客户端证书 "
echo " [STEP 2] 添加域名映射 "

# /etc/hosts中追加 镜像仓库IP 和 域名的映射
# VIP不为空，表示使用VIP作为域名解析的IP
# 删除已有的域名映射
if cat /etc/hosts | grep "${DOMAIN_NAME}"; then
  echo "check ${DOMAIN_NAME}  has added... delete"
  sed -i "/${DOMAIN_NAME}/d" /etc/hosts
fi
# 添加域名映射
if [ ! -z ${DOMAIN_IP} ]; then
   echo "${DOMAIN_IP}   ${DOMAIN_NAME}" >> /etc/hosts
fi


echo " [STEP 2] 成功添加域名映射 "

# 修改备用节点harbor配置并重启harbor

#./4-util/ssl/update_harbor_ssl.sh: 第 62 行:[: true: 期待一元表达式


if [ ! -z "${HARBOR_BACK_IP}" ]; then
  echo " [STEP 3 ] 为备用节点分发harbor和docker证书 "

  # 1. 拷贝Harbor证书
  echo " [1/3] 签发Harbor 证书 "
  ssh ${HARBOR_BACK_IP} " if [ ! -d "${CERT_GEN_PATH}" ];then mkdir -p ${CERT_GEN_PATH}; fi "
  # 复制服务器证书和密钥到 Harbor 主机上的 certficates 文件夹中。
  scp ${CERT_GEN_PATH}/${DOMAIN_NAME}.crt ${HARBOR_BACK_IP}:${CERT_GEN_PATH}/${DOMAIN_NAME}.crt
  scp ${CERT_GEN_PATH}/${DOMAIN_NAME}.key ${HARBOR_BACK_IP}:${CERT_GEN_PATH}/${DOMAIN_NAME}.key

  echo " [2/3] 签发Docker证书和系统证书 "

  # docker证书
  ssh ${HARBOR_BACK_IP} " if [ ! -d "/etc/docker/certs.d/${DOMAIN_NAME}:5000" ];then mkdir -p /etc/docker/certs.d/${DOMAIN_NAME}:5000; fi "

  scp ${CERT_GEN_PATH}/${DOMAIN_NAME}.cert ${HARBOR_BACK_IP}:/etc/docker/certs.d/${DOMAIN_NAME}:5000/
  scp ${CERT_GEN_PATH}/${DOMAIN_NAME}.key ${HARBOR_BACK_IP}:/etc/docker/certs.d/${DOMAIN_NAME}:5000/
  scp ${CERT_GEN_PATH}/ca.crt          ${HARBOR_BACK_IP}:/etc/docker/certs.d/${DOMAIN_NAME}:5000/

  # 系统证书
  ssh ${HARBOR_BACK_IP} " if [ ! -d "/etc/pki/ca-trust/source/anchors/" ];then mkdir -p /etc/pki/ca-trust/source/anchors/; fi "
  scp ${CERT_GEN_PATH}/${DOMAIN_NAME}.crt ${HARBOR_BACK_IP}:/etc/pki/ca-trust/source/anchors/${DOMAIN_NAME}.crt

  echo " [3/3] 添加域名映射 "
  # /etc/hosts中追加 镜像仓库IP 和 域名的映射
  # VIP不为空，表示使用VIP作为域名解析的IP
  # 删除已有的域名映射
  ssh ${HARBOR_BACK_IP} " if cat /etc/hosts | grep "${DOMAIN_NAME}"; then sed -i "/${DOMAIN_NAME}/d" /etc/hosts;  fi "
  # 添加域名映射
  if [ ! -z ${DOMAIN_IP} ]; then
     ssh ${HARBOR_BACK_IP} " echo '${DOMAIN_IP}   ${DOMAIN_NAME}' >> /etc/hosts"
  fi
  echo " [STEP 3 ] 成功为备用节点分发harbor和docker证书 "

fi
