#!/bin/bash
# https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/x86_64/
#variables : main directory
dockerdir=$(cd $(dirname $0);pwd)
#yum localinstall -y ${dockerdir}/*.rpm --nogpgcheck
for single_rpm in `ls ${dockerdir}/pkg/*.rpm`
do
    single_rpm=${single_rpm##*/}
	single_rpm=${single_rpm%.*}
	echo $single_rpm
	rpm -e $single_rpm
done