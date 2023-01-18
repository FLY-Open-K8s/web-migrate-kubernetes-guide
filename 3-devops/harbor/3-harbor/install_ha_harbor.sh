#!/bin/bash

#init path
exec_path=`pwd`
cd `dirname $0`
script_path=`pwd`
echo "[install harbor-ha script path]:" $script_path
pkg_path=pkg
cd $pkg_path

#check param
if [[ -z $1 || -z $2 || -z $3 ]]; then
	echo " LOCAL_IP OR HARBOR_VIP OR DATA_VOLUME is missing"
	echo "please execute the script in the following format,case: sh install_sothisai_harbor_local.sh LOCAL_IP HARBOR_VIP DATA_VOLUME"
	echo "Example: sh install_sothisai_harbor_local.sh 10.13.3.201 10.13.3.205 /public/home/harbordata"
	exit
fi

# 主机IP
LOCAL_IP=$1
# HARBOR NETWORK CIDR
HARBOR_NETWORK_CIDR=$2
#PG数据库的VIP
HARBOR_VIP=$3
# 数据目录
DATA_VOLUME=$4
# 域名
DOMAIN_NAME=$5
# 生成证书的路径
CERT_GEN_PATH=$6


# set check_harbor crontab
function set_cron(){
  #crontab
  if
    cat /etc/crontab | grep 'check_harbor'
  then
    echo "check_harbor crontab task has added... delete"
    sed -i '/check_harbor/d' /etc/crontab
  fi
  # 每3分钟 检测下Harbor状态
  echo "*/3 * * * * root sh /etc/vip/check_harbor.sh">>/etc/crontab

  systemctl restart crond.service
}



echo "start install harbor on node  `hostname`"
chmod +x docker-compose-Linux-x86_64
\cp docker-compose-Linux-x86_64 /usr/local/sbin/docker-compose
# 链接或复制到/usr/bin/下，防止sudo docker-compose出现command not found
cp /usr/local/sbin/docker-compose /usr/bin/docker-compose
docker-compose version

#解压harbor安装包
tar -zxvf harbor-offline-installer-v2.2.2.tgz  -C  /opt

# 提供的证书存在 不可用才走https的逻辑 crt和key 是harbor要使用的，cert和key是docker使用的，ca.crt是根证书
if [ ! -z "${CERT_GEN_PATH}" ]; then
    echo "use https protocol"
   # https配置
   \cp  harbor_https_ha.yml /opt/harbor/harbor.yml
   # 更新替换Habor的hostname
   sed -i "s/^hostname: .*/hostname: ${DOMAIN_NAME}/" /opt/harbor/harbor.yml
   # 更新替换cert
   sed -i "s#harborserver_crt#${CERT_GEN_PATH}/${DOMAIN_NAME}.crt#g" /opt/harbor/harbor.yml
   # 更新替换key
   sed -i "s#harborserver_key#${CERT_GEN_PATH}/${DOMAIN_NAME}.key#g" /opt/harbor/harbor.yml

else

  echo "use http protocol"

  \cp  harbor_http_ha.yml /opt/harbor/harbor.yml

  # 更新替换Habor-hostname
  sed -i "s/1.1.1.1/${LOCAL_IP}/g" /opt/harbor/harbor.yml

fi



# 更新替换Habor数据存储目录
sed -i "s#/nfs/data#${DATA_VOLUME}#g" /opt/harbor/harbor.yml
# 更新替换PG数据库的VIP
sed -i "s/10.0.0.0/${HARBOR_VIP}/g" /opt/harbor/harbor.yml



# 覆盖harbor原来的安装脚本，避免重复执行harbor的启动
\cp  install_aiharor.sh /opt/harbor/install_aiharor.sh
\cp  prepare_aiharor /opt/harbor/prepare_aiharor
dos2unix /opt/harbor/install_aiharor.sh
dos2unix /opt/harbor/prepare_aiharor
chmod 777 /opt/harbor/install_aiharor.sh
chmod 777 /opt/harbor/prepare_aiharor
sh /opt/harbor/install_aiharor.sh ${HARBOR_NETWORK_CIDR}



# 对harbor状态进行监控，监控脚本 check_harbor.sh
if [ ! -d "/etc/vip/" ];then
  mkdir /etc/vip
fi

cp ./vip/check_harbor.sh /etc/vip/check_harbor.sh
chmod 755 /etc/vip/check_harbor.sh
set_cron

# Harbor 自定义网段
#if [ ! -z "${HARBOR_NETWORK_CIDR}" ]; then
#  # 是否存在harbor网桥
#  harbor_network=`docker network ls | grep harbor | awk '{print $1}'`
#  if [[ ! -z ${harbor_network} ]]; then
#    docker network ls | grep harbor | awk '{print $1}' | xargs -t docker network rm
#  fi
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
    docker login -uadmin -pSugon@Harbor123 ${HARBOR_VIP}:5000
fi
if [ $? -eq 0 ];then
      echo " 登录harbor-成功! "
    else
      echo " 登录harbor-失败! "
      exit 2
fi
