#!/bin/sh
# 第一步，满足并行计算集群的特性：相互SSH免密码登录，go
cat /dev/zero | ssh-keygen -q -N "" > /dev/null
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
echo "        StrictHostKeyChecking no" >> /etc/ssh/ssh_config
# 第二步, 安装NFS相关组件，包括rpcbind(用于nfs服务器端) 和 nfs-utils(用于nfs客户端)组件
yum -y install nfs-utils rpcbind
mkdir -p /root/share && chmod 666 /root/share
# 第三步，安装c++编译器的相关package,包括glibc-headers gcc-c++ ，安装下载安装openmpi（此步骤比较耗时）
yum -y install glibc-headers gcc-c++
wget -P /tmp https://download.open-mpi.org/release/open-mpi/v3.1/openmpi-3.1.2.tar.gz
tar zxvf /tmp/openmpi-3.1.2.tar.gz -C /tmp
cd /tmp/openmpi-3.1.2 && ./configure && make && make install
which mpirun
