#!/bin/bash
GREEN_COL="\\033[32;1m"
RED_COL="\\033[1;31m"
NORMAL_COL="\\033[0;39m"

#check param
if [[ -z $1 || -z $2 ]]; then
	echo " SOURCE_REGISTRY OR TARGET_REGISTRY OR HARBOR_ADMIN_PASSWORD is missing"
	echo "please execute the script in the following format,case: sh skopeo_transfer_image.sh SOURCE_REGISTRY TARGET_REGISTRY HARBOR_ADMIN_PASSWORD"
	echo "Example: sh skopeo_transfer_image.sh 10.0.35.26:5000 10.6.6.215:5000 Sugon@Harbor123 "
	exit
fi

# 源Harbor地址
SOURCE_REGISTRY=$1
# 目标Harbor地址
TARGET_REGISTRY=$2
# Harbor 管理员用户密码
HARBOR_AUTH=admin:$3
# 待同步的镜像列表
IMAGES_LIST_FILE="registry-images-list.txt"

set -eo pipefail

CURRENT_NUM=0
ALL_IMAGES="$(sed -n '/#/d;s/:/:/p' ${IMAGES_LIST_FILE} | sort -u)"
TOTAL_NUMS=$(echo "${ALL_IMAGES}" | wc -l)
echo -e "Starting 【Image Trasfer】:  sync $1 to $2 ,\n 【Image Total Nums】： ${TOTAL_NUMS}, \n 【Image List】：\n ${ALL_IMAGES} "

# 镜像复制方法
skopeo_copy() {

  #    skopeo version 0.1.40/1.4.1 写法
 #   skopeo copy --src-tls-verify=false --dest-tls-verify=false --dest-creds admin:Sugon@Harbor123  \
 #    docker://nixos/nix:2.3.12 docker://10.6.6.214:5000/cpu/admin/nixos/nix:2.3.12
   if skopeo copy docker://$1 docker://$2 \
         --src-tls-verify=false --dest-tls-verify=false --dest-creds ${HARBOR_AUTH}; then
      echo -e "$GREEN_COL Progress: ${CURRENT_NUM}/${TOTAL_NUMS} sync $1 to $2 successful $NORMAL_COL"
   else
      echo -e "$RED_COL Progress: ${CURRENT_NUM}/${TOTAL_NUMS} sync $1 to $2 failed $NORMAL_COL"
      if [ ! -f "failed_syc_harbor_image_list.txt" ];then
          touch  failed_syc_harbor_image_list.txt
      fi
      echo "$1" >> failed_syc_harbor_image_list.txt
      # 失败
      # exit 2
   fi
}
# 执行复制
for image in ${ALL_IMAGES}; do
 let CURRENT_NUM=${CURRENT_NUM}+1
 skopeo_copy ${SOURCE_REGISTRY}/${image} ${TARGET_REGISTRY}/${image}
done