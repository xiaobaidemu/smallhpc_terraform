#!/bin/sh
# 需要等nfs master节点创建完成后，等待30s在挂载NFS文件目录
remoteIp="172.16.0.1"
# 等待30s确保master中NFS 服务已经启动好
sleep 30
mkdir -p /root/share
showmount -e ${remoteIp}
mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${remoteIp}:/root/share /root/share