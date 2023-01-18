#!/bin/bash

# Harbor 状态
harborState=$(docker-compose  -f /opt/harbor/docker-compose.yml ps | grep "Up (healthy)" | wc -l)
echo "【Harbor 状态(8-组件都健康；非8-组件不健康)】:" ${harborState}
if [ "${harborState}" -ne 8 ]; then
# 检查进程是否存在，如果存在检查联通性，如果联通了。则返回0， 如果不存在或者不联通则返回1
echo 'Harbor 组件不健康'
docker-compose -f /opt/harbor/docker-compose.yml up  -d --force-recreate
fi