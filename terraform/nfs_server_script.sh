#!/bin/sh
mkdir -p /root/share && chmod 666 /root/share && cd /root/share && touch test_file.txt
mkdir -p /tmp/subnode_file
echo "/root/share 172.16.0.0/21(insecure,rw,no_root_squash,no_all_squash,sync)" >> /etc/exports && exportfs -r
service rpcbind start
service nfs restart
rpcinfo -p localhost
showmount -e localhost