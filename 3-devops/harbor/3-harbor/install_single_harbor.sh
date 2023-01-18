#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install harbor-single script path]:" $script_path
pkg_path=pkg
cd $pkg_path

#check param
if [ -z $1 ]; then
	echo " HARBOR_IP is missing"
	echo "please execute the script in the following format,case: sh install_single_harbor.sh HARBOR_IP"
	echo "Example: sh install_single_harbor.sh 10.13.3.201 "
	exit
fi

# HARBOR 主机IP
HARBOR_IP=$1
# HARBOR NETWORK CIDR
HARBOR_NETWORK_CIDR=$2
# 数据目录
DATA_VOLUME=$3
# 域名
DOMAIN_NAME=$4
# 生成证书的路径
CERT_GEN_PATH=$5


echo "start install harbor on node ${HARBOR_IP}"
chmod +x docker-compose-Linux-x86_64
\cp docker-compose-Linux-x86_64 /usr/local/sbin/docker-compose
# 链接或复制到/usr/bin/下，防止sudo docker-compose出现command not found
cp /usr/local/sbin/docker-compose /usr/bin/docker-compose
docker-compose version

#解压harbor安装包
tar -zxvf harbor-offline-installer-v2.2.2.tgz  -C  /opt

if [ ! -z "${CERT_GEN_PATH}" ]; then
    echo "use https protocol"

   # https配置
   \cp  harbor_https_single.yml /opt/harbor/harbor.yml
   # 更新替换Habor的hostname
   sed -i "s/^hostname: .*/hostname: ${DOMAIN_NAME}/" /opt/harbor/harbor.yml
   # 更新替换cert
   sed -i "s#harborserver_crt#${CERT_GEN_PATH}/${DOMAIN_NAME}.crt#g" /opt/harbor/harbor.yml
   # 更新替换key
   sed -i "s#harborserver_key#${CERT_GEN_PATH}/${DOMAIN_NAME}.key#g" /opt/harbor/harbor.yml

  else

    echo "use http protocol"

    \cp  harbor_http_single.yml /opt/harbor/harbor.yml
    # 更新替换Habor-hostname
    sed -i "s/harbor_ip/${HARBOR_IP}/g" /opt/harbor/harbor.yml
fi

# 更新替换Habor数据存储目录
sed -i "s#/nfs/data#${DATA_VOLUME}#g" /opt/harbor/harbor.yml

# 覆盖harbor原来的安装脚本，避免重复执行harbor的启动
\cp  install_aiharor.sh /opt/harbor/install_aiharor.sh
\cp  prepare_aiharor /opt/harbor/prepare_aiharor
dos2unix /opt/harbor/install_aiharor.sh
dos2unix /opt/harbor/prepare_aiharor
chmod 777 /opt/harbor/install_aiharor.sh
chmod 777 /opt/harbor/prepare_aiharor
sh /opt/harbor/install_aiharor.sh ${HARBOR_NETWORK_CIDR}

# Harbor 自定义网段
#if [ ! -z "${HARBOR_NETWORK_CIDR}" ]; then
#  # 是否存在harbor网桥
#  harbor_network=`docker network ls | grep harbor | awk '{print $1}'`
#  if [[ ! -z ${harbor_network} ]]; then
#    docker network ls | grep harbor | awk '{print $1}' | xargs -t docker network rm
#  fi
#
#  # 创建Harbor新的网桥
#  docker network create --driver=bridge --subnet=${HARBOR_NETWORK_CIDR} harbor
#  # 更新替换Habor-hostname
#  sed -i "s/external: false/external: true/" /opt/harbor/docker-compose.yml
#fi


# 服务器重启，自动登录Harbor
if cat /etc/rc.d/rc.local | grep 'docker login' ;then
  echo "docker login has added... delete"
  sed -i '/docker login/d' /etc/rc.d/rc.local
fi

if [ ! -z ${CERT_GEN_PATH} ]; then
    echo "docker login -uadmin -pSugon@Harbor123 ${DOMAIN_NAME}:5000" >> /etc/rc.d/rc.local
  else
    echo "docker login -uadmin -pSugon@Harbor123 ${HARBOR_IP}:5000" >> /etc/rc.d/rc.local
fi


# 配置harbor为系统服务，并启动harbor
\cp ./system_servie/harbor.service /etc/systemd/system/harbor.service
sh ./system_servie/config_harbor_systemd_service.sh
sleep 50

# 登录harbor
if [ ! -z "${CERT_GEN_PATH}" ]; then
    docker login -uadmin -pSugon@Harbor123 ${DOMAIN_NAME}:5000
  else
    docker login -uadmin -pSugon@Harbor123 ${HARBOR_IP}:5000
fi
if [ $? -eq 0 ];then
      echo " 登录harbor-成功! "
    else
      echo "登录harbor-失败!"
      exit 2
fi


