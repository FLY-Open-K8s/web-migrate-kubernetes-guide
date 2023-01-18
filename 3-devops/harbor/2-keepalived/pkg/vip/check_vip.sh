#!/bin/bash

pgstate=$(netstat -na|grep "LISTEN"|grep "5432"|wc -l)
echo "【PG 状态(0-不活跃；非0-活跃)】:" ${pgstate}

kpstate=$(systemctl status keepalived | grep -v grep | grep "active (running)" |wc -l)
echo "【keepalived 状态(0-不活跃；非0-活跃)】:" ${kpstate}

# PG正常，并且keepalived不正常，重启keepalived
if [ "${pgstate}" -ne 0 ] && [ "${kpstate}" -eq 0 ]; then
echo 'PG正常，keepalived不正常，重启keepalived'

systemctl restart keepalived && systemctl status keepalived

fi

# 是否是VIP节点
isVIPNode=$(ip addr | grep "1.1.1.1" | wc -l)
echo "【是否是VIP节点 状态(0-不是VIP节点；非0-是VIP节点)】:" ${isVIPNode}

# 不是PG主节点； 却是VIP节点
# 有时候可能存在备用节点完全宕机，这时候仅剩一个节点，通过
# https://cdn.modb.pro/db/230806
if [ "${pgstate}" -ne 0 ] && [ "${isVIPNode}" -ne 0 ]; then
# 检查进程是否存在，如果存在检查联通性，如果联通了。则返回0， 如果不存在或者不联通则返回1
#  -- 也可以查看这个，主库是f代表false ；备库是t，代表true
#例如：
# docker exec -it pg-0 /bin/bash
# docker exec -it pg-1 /bin/bash
# export PGPASSWORD=root123
# psql -h 127.0.0.1 -d registry -U postgres
# select pg_is_in_recovery();
echo 'PG正常; 是VIP节点'

  echo '延迟80S, 等待主从切换成功，判断是否PG主节点'
  sleep 80
	# 是否PG主节点
	isPgMaster=$(ps -ef | grep postgres | grep "wal sender"|wc -l)
	echo "【是否PG主节点 状态(0-备节点；非0-主节点)】:" ${isPgMaster}
  if [ "${isPgMaster}" -eq 0 ] ; then
    echo 'PG正常; 不是PG主节点; 却是VIP节点'
    systemctl stop keepalived
  fi

fi

