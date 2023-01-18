#!/bin/bash


#check param
if [[ -z $1 || -z $2  || -z $3 ]]; then
	echo " HARBOR_IP OR DOMAIN_NAME  OR CERT_GEN_PATH is missing"
	echo "please execute the script in the following format,case: sh gen_harbor_cert.sh HARBOR_IP DOMAIN_NAME CERT_GEN_PATH"
	echo "Example: sh gen_harbor_cert.sh 10.6.6.215 image.ac.com /opt/harbor_cert "
	exit
fi

# Harbor地址 或者 VIP
HARBOR_IP=$1
# 域名
DOMAIN_NAME=$2
# 生成证书的路径
CERT_GEN_PATH=$3


# 生成证书的路径
# 判断文件夹是否存在
if [ ! -d "${CERT_GEN_PATH}" ];then
  mkdir -p ${CERT_GEN_PATH}
else
  echo "${CERT_GEN_PATH} 文件夹已经存在"
fi

# 进入证书文件夹
cd ${CERT_GEN_PATH}
 

#1. 生成CA根证书
#生成私钥
echo " [1/5] 生成CA根证书 "
openssl genrsa -out ca.key 4096
# 生成 CA 证书
openssl req -x509 -new -nodes -sha512 -days 36500 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=${DOMAIN_NAME}" -key ca.key -out ca.crt

# 2. 生成Harbor服务器证书
echo " [2/5] 生成Harbor服务器证书 "
# 生成私钥
openssl genrsa -out ${DOMAIN_NAME}.key 4096
# 生成证书签名请求
openssl req -sha512 -new -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=${DOMAIN_NAME}" -key ${DOMAIN_NAME}.key -out ${DOMAIN_NAME}.csr

# 生成 x509 v3 扩展文件
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
 
[alt_names]
DNS.1=${DOMAIN_NAME}
DNS.2=image.ac
DNS.3=harbor
EOF
 
# 使用v3.ext文件为你的 Harbor 主机生成证书
openssl x509 -req -sha512 -days 36500 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in ${DOMAIN_NAME}.csr -out ${DOMAIN_NAME}.crt
 
# 3. 签发Harbor证书
echo " [3/5] 签发Harbor 证书 "
# 复制服务器证书和密钥到 Harbor 主机上的 certficates 文件夹中。
#cp ${CERT_GEN_PATH}/${DOMAIN_NAME}.crt ${CERT_GEN_PATH}/${DOMAIN_NAME}.crt
#cp ${CERT_GEN_PATH}/${DOMAIN_NAME}.key ${CERT_GEN_PATH}/${DOMAIN_NAME}.key

# 4. 签发Docker证书
echo " [4/5] 签发Docker证书 "
openssl x509 -inform PEM -in ${DOMAIN_NAME}.crt -out ${DOMAIN_NAME}.cert

if [ ! -d "/etc/docker/certs.d/${DOMAIN_NAME}:5000" ];then
  mkdir -p /etc/docker/certs.d/${DOMAIN_NAME}:5000
else
  echo "/etc/docker/certs.d/${DOMAIN_NAME}:5000 文件夹已经存在"
fi

# 复制证书
# 以下示例说明了docker使用自定义证书的配置。
# /etc/docker/certs.d/
#     └── ${DOMAIN_NAME}:5000
#        ├── ${DOMAIN_NAME}:5000.cert  <-- Server certificate signed by CA
#        ├── ${DOMAIN_NAME}:5000.key   <-- Server key signed by CA
#        └── ca.crt             <-- Certificate authority that signed the registry certificate
#cp ${CERT_GEN_PATH}/${DOMAIN_NAME}.cert /etc/docker/certs.d/${DOMAIN_NAME}:5000/
#cp ${CERT_GEN_PATH}/${DOMAIN_NAME}.key /etc/docker/certs.d/${DOMAIN_NAME}:5000/
#cp ${CERT_GEN_PATH}/ca.crt          /etc/docker/certs.d/${DOMAIN_NAME}:5000/
cp ${CERT_GEN_PATH}/${DOMAIN_NAME}.cert /etc/docker/certs.d/${DOMAIN_NAME}:5000/
cp ${CERT_GEN_PATH}/${DOMAIN_NAME}.key /etc/docker/certs.d/${DOMAIN_NAME}:5000/
cp ${CERT_GEN_PATH}/ca.crt          /etc/docker/certs.d/${DOMAIN_NAME}:5000/


# 5. 添加操作系统级别信任证书
echo " [5/5] 添加操作系统级别信任证书 "
if [ ! -d "/etc/pki/ca-trust/source/anchors/" ];then
  mkdir -p /etc/pki/ca-trust/source/anchors/
else
  echo "/etc/pki/ca-trust/source/anchors/ 文件夹已经存在"
fi
cp ${DOMAIN_NAME}.crt /etc/pki/ca-trust/source/anchors/${DOMAIN_NAME}.crt
# 更新系统证书
update-ca-trust

# 清理无用的中间文件
rm -rf ${CERT_GEN_PATH}/ca.key
rm -rf ${CERT_GEN_PATH}/ca.srl
rm -rf ${CERT_GEN_PATH}/v3.ext
rm -rf ${CERT_GEN_PATH}/${DOMAIN_NAME}.csr