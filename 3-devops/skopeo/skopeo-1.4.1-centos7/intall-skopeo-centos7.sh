#!/bin/bash
# https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/x86_64/
#variables : main directory

# 判断 /etc/containers/policy.json是否存在
if [ ! -f "/etc/containers/policy.json" ];then
  # /etc/containers/ 文件夹是否存在
  if [ ! -d "/etc/containers/" ];then
    mkdir /etc/containers
  else
    echo "/etc/containers/ 文件夹已经存在"
  fi
  touch /etc/containers/policy.json

else
  echo "/etc/containers/policy.json 文件存在"
fi

echo "【安装Skopeo】更新/etc/containers/policy.json 存在"
cat>/etc/containers/policy.json<<EOF
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports":
        {
            "docker-daemon":
                {
                    "": [{"type":"insecureAcceptAnything"}]
                }
        }
}
EOF

echo "【安装Skopeo】执行中..."
dockerdir=$(cd $(dirname $0);pwd)
#yum localinstall -y ${dockerdir}/*.rpm --nogpgcheck
for single_rpm in `ls ${dockerdir}/pkg/*.rpm`
do
    rpm -ivh --nodeps --force $single_rpm
done