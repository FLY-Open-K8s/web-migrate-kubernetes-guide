#!/bin/bash
pgstate=$(netstat -na|grep "LISTEN"|grep "5432"|wc -l)
echo "【PG 状态(0-不活跃；非0-活跃)】:" ${pgstate}
# 是否主节点
isPgMaster=$(ps -ef | grep postgres | grep "wal sender"|wc -l)
echo "【是否PG主节点 状态(0-备节点；非0-主节点)】:" ${isPgMaster}
# 是否是VIP节点
isVIPNode=$(ip addr | grep "1.1.1.1" | wc -l)
echo "【是否是VIP节点 状态(0-不是VIP节点；非0-是VIP节点)】:" ${isVIPNode}

if [ "${pgstate}" -eq 0 ] ; then
# 检查进程是否存在，如果存在检查联通性，如果联通了。则返回0， 如果不存在或者不联通则返回1
echo 'PG 状态不正常'
systemctl stop keepalived
fi


#harborState=$(docker-compose  -f /opt/harbor/docker-compose.yml ps | grep "Up" | wc -l)
#echo "【Harbor 状态(8-组件都健康；非8-组件不健康)】:" ${harborState}
#if [ "${harborState}" -ne 8 ]; then
## 检查进程是否存在，如果存在检查联通性，如果联通了。则返回0， 如果不存在或者不联通则返回1
#echo 'Harbor 组件不健康'
#systemctl stop keepalived
#fi

# 杀掉占用5433端口的PG进程
#docker rm -f `docker ps -a|grep "5432"|awk '{print $1}'`
#echo '杀掉占用5432端口的PG进程'

# 停止Harbor服务
#docker-compose -f /opt/harbor/docker-compose.yml down
#echo '停止Harbor服务'