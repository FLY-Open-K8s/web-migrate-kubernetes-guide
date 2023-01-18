#!/bin/bash

# 复制 harbor.service
#\cp harbor.service /etc/systemd/system/harbor.service
dos2unix /etc/systemd/system/harbor.service

# 赋予执行权限
chmod 777 /etc/systemd/system/harbor.service
# 重新加载服务的配置文件
systemctl daemon-reload
# 设置开机自启
systemctl enable harbor
# 重启harbor
systemctl restart harbor