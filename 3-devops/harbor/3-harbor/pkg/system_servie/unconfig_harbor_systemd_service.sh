#!/bin/bash

# 删除 harbor.service
rm -rf /etc/systemd/system/harbor.service
rm -rf /etc/systemd/system/multi-user.target.wants/harbor.service

# 重新加载服务的配置文件
systemctl daemon-reload

