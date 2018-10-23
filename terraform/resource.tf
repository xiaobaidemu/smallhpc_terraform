# Configure the Alicloud Provider
# 创建一个拥有公网IP的ECS服务器，且需要运行脚本命令初始化服务器
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}
# 创建一个vpc
resource "alicloud_vpc" "vpc" {
  name       = "small_hpc_vpc"
  cidr_block = "172.16.0.0/12"
  description ="this is a example vpc for small_hpc_cluster"
}
# 创建一个vswitch,vsw的创建依赖于vpc的创建，即vsw必须附属于某一个vpc
resource "alicloud_vswitch" "vsw" {
  name              = "small_hpc_vsw"
  vpc_id            = "${alicloud_vpc.vpc.id}"
  cidr_block        = "${var.cidr_block}"
  availability_zone = "${var.zoneid}"
  description       = "this is a example vsw for small_hpc_cluster"
}
# 基于某一个VPC创建安全组
resource "alicloud_security_group" "group" {
  name   = "small_hpc_security_group"
  vpc_id = "${alicloud_vpc.vpc.id}"
}
# 创建一个安全组
resource "alicloud_security_group" "default" {
  name        = "small_hpc_default"
  description = "a security for small_hpc_default"
  vpc_id      = "${alicloud_vpc.vpc.id}"
}
# 获取镜像的id
data "alicloud_images" "images_ds" {
  owners = "self"
  name_regex = "^small_hpc_image"
}
# 创建一个实例，同时这个实例也作为NFS的Server运行
# Create a machine and at same time this machine is NFS server
resource "alicloud_instance" "master" {
  availability_zone = "${var.zoneid}"
  image_id        = "${data.alicloud_images.images_ds.images.0.id}"
  security_groups = ["${alicloud_security_group.default.id}"]
  instance_name   = "${var.base_nstance_name}"
  instance_type   = "${var.instance_type}"
  vswitch_id      = "${alicloud_vswitch.vsw.id}"
  internet_charge_type  = "${var.internet_charge_type}"
  internet_max_bandwidth_out = "1"
  user_data       = "#!/bin/sh\n mkdir -p /root/share"
  host_name        = "hpc0"
  password         = "${var.password}"
  private_ip      = "${cidrhost(var.cidr_block, count.index+1)}"
  provisioner "file" {
    source      = "nfs_server_script.sh"
    destination = "/tmp/nfs_server_script.sh"
  }
  provisioner "file" {
    source      = "mpi_testfile"
    destination = "/root/share"
  }
  provisioner "remote-exec" {
    inline = [
      "cd /tmp && chmod 700 nfs_server_script.sh",
      "./nfs_server_script.sh > nfs_server_script_log",
    ]
   }
   connection {
    host     = "${alicloud_instance.master.public_ip}"
    type     = "ssh"
    user     = "root"
    password = "${alicloud_instance.master.password}"
    timeout  = "10s"
  }
}
output "public_ip" {
  value = "${alicloud_instance.master.public_ip}"
}

# 创建两个安全组规则，一个是为了方面SSH登录，允许22端口入方向
resource "alicloud_security_group_rule" "allow_22_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = "${alicloud_security_group.default.id}"
  cidr_ip           = "0.0.0.0/0"
}
resource "alicloud_security_group_rule" "allow_icmp"{
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = "${alicloud_security_group.default.id}"
  cidr_ip           = "0.0.0.0/0"
}
# 创建其他节点，同事其他节点也作为NFS的client节点
resource "alicloud_instance" "slave" {
  count           = "${var.node_count}"
  availability_zone = "${var.zoneid}"
  image_id        = "${data.alicloud_images.images_ds.images.0.id}"
  security_groups = ["${alicloud_security_group.default.id}"]
  instance_name   = "${var.base_nstance_name}"
  instance_type   = "${var.instance_type}"
  vswitch_id      = "${alicloud_vswitch.vsw.id}"
  internet_charge_type  = "${var.internet_charge_type}"
  host_name        = "hpc${count.index+1}"
  private_ip      =  "${cidrhost(var.cidr_block, count.index+2)}"
  user_data       = "${file("nfs_client_script.sh")}"
  depends_on = ["alicloud_instance.master"]
}
