#!/bin/bash

# 后台执行： nohup sh harbor_transfer.sh 10.0.35.26:5000 Sugon@Harbor123 10.6.6.215:5000 2>&1 &
#check param
if [[ -z $1 || -z $2  || -z $3 ]]; then
	echo " SOURCE_REGISTRY OR TARGET_REGISTRY is missing"
	echo "please execute the script in the following format,case: sh harbor_transfer.sh SOURCE_REGISTRY HARBOR_ADMIN_PASSWORD TARGET_REGISTRY"
	echo "Example: sh harbor_transfer.sh 10.0.35.26:5000 Sugon@Harbor123 10.6.6.215:5000 "
	exit
fi

# 源Harbor地址
SOURCE_REGISTRY=$1
# 目标Harbor管理员用户密码
HARBOR_ADMIN_PASSWORD=$2
# 目标Harbor地址
TARGET_REGISTRY=$3
# 1. 导出镜像列表
echo -e "【 1/2 Harbor迁移-导出镜像列表】:存放 harbor-images-list.txt"
sh -v list_harbor_image.sh ${SOURCE_REGISTRY} ${HARBOR_ADMIN_PASSWORD}

# 2. 迁移镜像
echo -e "【 2/2 Harbor迁移-迁移镜像】:遍历 harbor-images-list.txt"
sh -v skopeo_transfer_image.sh ${SOURCE_REGISTRY} ${TARGET_REGISTRY} ${HARBOR_ADMIN_PASSWORD}