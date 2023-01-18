#!/bin/bash
#镜像清单文件，将获取到的镜像信息存到该文件中

#check param
if [[ -z $1 || -z $2 ]]; then
	echo "SOURCE_REGISTRY OR TARGET_REGISTRY is missing"
	echo "please execute the script in the following format,case: sh list_harbor_image.sh HARBOR_ADDR HARBOR_ADMIN_PASSWORD"
	echo "Example: sh list_harbor_image.sh 10.0.35.26:5000 Sugon@Harbor123 "
	exit
fi

# Harbor连接地址
HARBOR_ADDR=$1
# Harbor 管理员用户密码
HARBOR_AUTH=admin:$2
 #镜像清单文件
IMAGES_FILE=harbor-images-list.txt
# 显示脚本执行过程，并显示脚本对变量的处理结果。
# set -x
# 获取所有镜像清单
Project_List=$(curl -s -u ${HARBOR_AUTH}  -H "Content-Type: application/json" -X GET  http://${HARBOR_ADDR}/api/v2.0/projects?page_size=100  | python -m json.tool | grep name | awk '/"name": /' | awk -F '"' '{print $4}')
echo -e "【Harbor<${HARBOR_ADDR}>项目列表】: \n ${Project_List}"

# 遍历Harbor项目
for Project in $Project_List;do
    # 某个项目内的镜像列表-页码
    PAGE_NUM=1
    while true; do
       Image_Names=$(curl -s -u ${HARBOR_AUTH} -X GET "http://${HARBOR_ADDR}/api/v2.0/projects/$Project/repositories?page_size=100&page=${PAGE_NUM}" | python -m json.tool | grep name | awk '/"name": /' | awk -F '"' '{print $4}')
       Image_Size=`echo  "${Image_Names}" | wc -l`
       echo -e "【Harbor<${HARBOR_ADDR}>, 项目<${Project}>镜像列表大小<${Image_Size}>, 详情】: \n ${Image_Names}"
       for Image in $Image_Names;do
           Image_Tags=$(curl -s -u ${HARBOR_AUTH}  -H "Content-Type: application/json"   -X GET  http://${HARBOR_ADDR}/v2/$Image/tags/list |  awk -F '"'  '{print $8,$10,$12}')

           for Tag in $Image_Tags;do
             if [ ! -z "${Tag}" ] || [[ ! ${Tag} =~ 400 ]] ||[[ ! ${Tag} =~ 404 ]];then
               echo "$Image:$Tag"   >> ${IMAGES_FILE}
             fi
           done
       done
       # 当前页码的列表数量<100
       if [ "${Image_Size}" -lt "100" ]; then
           break
       else
          let PAGE_NUM=${PAGE_NUM}+1
       fi

    done

done