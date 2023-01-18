#!/bin/bash
#镜像清单文件，将获取到的镜像信息存到该文件中

#check param
if [[ -z $1 ]]; then
	echo "SOURCE_REGISTRY is missing"
	echo "please execute the script in the following format,case: sh list_registry_image.sh SOURCE_REGISTRY "
	echo "Example: sh list_registry_image.sh 10.6.6.213:5001 "
	exit
fi

# Registry 连接地址
REGISTRY_ADDR=$1

 #镜像清单文件
IMAGES_FILE=registry-images-list.txt

# Registry镜像列表
# shellcheck disable=SC2006
Image_Names=`curl -s ${REGISTRY_ADDR}/v2/_catalog?n=10000 | json_reformat | json_reformat | jq '.repositories'`
# shellcheck disable=SC2068
# shellcheck disable=SC2145
echo -e "【Registry<${REGISTRY_ADDR}>, 镜像列表】: \n ${Image_Names[@]}"

# shellcheck disable=SC1061
# shellcheck disable=SC2068
for Image in ${Image_Names[@]};do

    # 处理输出
    if [[ ${Image} == "[" ]]; then
      continue
    fi
    if [[ ${Image} == "]" ]]; then
      continue
    fi
    if [[ ${Image} == null ]]; then
           			continue
    fi
    Image=(`echo ${Image} | tr -d ','`)
    Image=(`echo ${Image} | tr -d '"'`)

    # 镜像TAG
  	Image_Tags_Url=${REGISTRY_ADDR}/v2/${Image}/tags/list
  	# shellcheck disable=SC2006
  	Image_Tags=`curl -s ${Image_Tags_Url} | json_reformat | json_reformat | jq '.tags'`
  	echo -e "【镜像<${Image_Tags_Url}>, Tag列表】: \n ${Image_Tags}"

    # 遍历镜像的TAG列表
   	for tag in ${Image_Tags[@]};do
   	  # 处理输出
   		if [[ ${tag} == "[" ]]; then
   		continue
   		fi
   		if [[ ${tag} == "]" ]]; then
   		continue
   		fi
   		if [[ ${tag} == null ]]; then
   			continue
   		fi
   		tag=(`echo ${tag} | tr -d ','`)
   		tag=(`echo ${tag} | tr -d '"'`)

      echo "${Image}:${tag}"   >> ${IMAGES_FILE}
    done

done
