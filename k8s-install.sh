sudo qemu-img create -f qcow2 centos8.img 180G


sudo virt-install --name "centos8" \
--os-variant centos8 --memory 4096 \
--vcpus 2 --disk /home/lemon/ssd_data_lv/kvm/centos8/centos8.img \
--cdrom /home/lemon/data/Downloads/CentOS-8.3.2011-x86_64-dvd1.iso  \
--network bridge=virbr0 --graphics vnc,listen=0.0.0.0,keymap=en-us  \
--import


sudo qemu-img create -f qcow2 centos6.img 120G

sudo virt-install --name "centos6.5" \
--os-variant centos6.5 --memory 1024  \
--vcpus 2 --disk /home/lemon/ssd_data_lv/kvm/centos6.5/centos6.img  \
--cdrom /home/lemon/Downloads/CentOS-6.5-x86_64-bin-DVD1.iso \
--network bridge=virbr0 --graphics vnc,listen=0.0.0.0,keymap=en-us \
--import


#multi user login


#list vm
virsh list

#clone vm
virt-clone --original ubuntu1804 --name ubuntu1804_org --file /var/kvm/images/ubuntu1804_org.img
virt-clone --original centos8 --name k8s-master1 --file  /home/lemon/ssd_data_lv/kvm/k8s-master1/ck8s-master1.img
virt-clone --original centos8 --name k8s-master2 --file  /home/lemon/ssd_data_lv/kvm/k8s-master2/k8s-master2.img
virt-clone --original centos8 --name k8s-master3 --file  /home/lemon/ssd_data_lv/kvm/k8s-master3/k8s-master3.img
virt-clone --original centos8 --name k8s-node1 --file  /home/lemon/ssd_data_lv/kvm/k8s-node1/k8s-node1.img
virt-clone --original centos8 --name k8s-node2 --file  /home/lemon/ssd_data_lv/kvm/k8s-node2/k8s-node2.img
virt-clone --original centos8 --name k8s-node3 --file  /home/lemon/ssd_data_lv/kvm/k8s-node3/k8s-node3.img
virt-clone --original centos8 --name k8s-nginx-master --file  /home/lemon/ssd_data_lv/kvm/k8s-nginx/k8s-nginx.img
virt-clone --original centos8 --name k8s-nginx-slave --file  /home/lemon/ssd_data_lv/kvm/k8s-nginx-slave/k8s-nginx-slave.img
virt-clone --original centos8 --name k8s-gitserver --file  /home/lemon/ssd_data_lv/kvm/k8s-harbor/k8s-gitserver.img


#list dhcp
virsh net-dhcp-leases default

#add net dev


#ubuntun 網卡管理命令
$ sudo ip link set enp0s3 down
$ sudo ip link set enp0s3 up


#hostsnames
192.168.122.100 k8s-master1
192.168.122.101 k8s-master2
192.168.122.102 k8s-master3
192.168.122.100 k8s-etcd1
192.168.122.101 k8s-etcd2
192.168.122.102 k8s-etcd3
192.168.122.103 k8s-node1
192.168.122.104 k8s-node2
192.168.122.105 k8s-node3


virsh start 
for i in k8s-master1 k8s-master2 k8s-master3 k8s-node1 k8s-node2 k8s-node3 k8s-nginx-master k8s-nginx-slave k8s-k8sgitserver k8s-harbor; do echo $i && virsh start $i; done;
for i in k8s-master1 k8s-master2 k8s-master3 k8s-node1 k8s-node2 k8s-node3 k8s-nginx-master k8s-nginx-slave k8s-k8sgitserver k8s-harbor; do echo $i && virsh desstory $i; done;
#
52:54:00:7d:62:ef nginx
52:54:00:bf:9d:70 harbor

#install harbor server
1.install docker
# 移除原先安装过的docker组件
$ sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# 安装yum-utils
$ sudo yum install -y yum-utils
# 添加Docker软件源
$ sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# 安装docker-ce,docker-ce-cli,containerd.io
$ sudo yum install docker-ce docker-ce-cli containerd.io

# 安装完成后启动docker
$ sudo systemctl start docker
# 启动docker后设置Dokcer以后开机自启动
$ sudo systemctl enable docker

2.install harbor
2.1 download harbor
wget https://github.com/goharbor/harbor/releases/download/v2.0.1/harbor-offline-installer-v2.0.1.tgz

2.2 tar xvf
$ tar zxf harbor-offline-installer-v2.0.1.tgz  -C /usr/local/
$ cd /usr/local/harbor/


3.配置SSL证书
3.1 自定义证书
官方文档：https://goharbor.io/docs/2.0.0/install-config/configure-https/
　- 生成私钥

 openssl req -x509 -new -nodes -sha512 -days 3650

 生成CA证书
 openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=GDSZ/L=GD/O=LEMON/OU=MFZ/CN=k8s-harbor.gdsz.com" -key ca.key -out ca.crt


mkdir /data/cert/
cp ca.crt  ca.key  /data/cert/
openssl genrsa -out k8s-harbor.gdsz.com.key 4096
openssl req -sha512 -new  -subj /"C=CN/ST=SZ/L=SZ/O=LEMON/OU=PERSONAL/CN=k8s-harbor.gdsz.com" -key k8s-harbor.gdsz.com.key -out k8s-harbor.gdsz.com.csr
openssl x509 -req -sha512 -days 3650 -CA ca.crt -CAkey ca.key -CAcreateserial -in  k8s-harbor.gdsz.com.csr -out  k8s-harbor.gdsz.com.crt
openssl x509 -inform PEM -in k8s-harbor.gdsz.com.crt -out k8s-harbor.gdsz.com.cert

mkdir -p /etc/docker/certs.d/
cp  k8s-harbor.gdsz.com.cert k8s-harbor.gdsz.com.key  ca.crt /etc/docker/certs.d/

3.2 install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

3.3 isntall
./prepare
./install.sh



==================================================

#配置所有節點的信任關系



#close fw
关闭防火墙和selinux
systemctl stop firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing\/SELINUX=disabled/' /etc/selinux/config

# 关闭交换分区
swapoff -a
永久关闭，修改/etc/fstab,注释掉swap一行
#/dev/mapper/cl-swap     none                    swap    defaults        0 0


#时间同步
yum install -y chrony
systemctl start chronyd
systemctl enable chronyd
chronyc sources

#修改内核参数
cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


#加载ipvs模块
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
lsmod | grep ip_vs
lsmod | grep nf_conntrack_ipv4
yum install -y ipvsadm


#配置工作目录
每台机器都需要配置证书文件、组件的配置文件、组件的服务启动文件，现专门选择 master1 来统一生成这些文件，然后再分发到其他机器。以下操作在 master1 上进行
[root@master1 ~]# mkdir -p /data/work
注：该目录为配置文件和证书文件生成目录，后面的所有文件生成相关操作均在此目录下进行
[root@master1 ~]# ssh-keygen -t rsa -b 2048
将秘钥分发到另外五台机器，让 master1 可以免密码登录其他机器


#搭建etcd集群

##配置etcd工作目录
etc/etcd                     # 配置文件存放目录
/etc/etcd/ssl               # 证书文件存放目录

./sshTool -r cmd -u root -l -h 192.168.122.100-102 -P 22 -k id_rsa  -c "mkdir -p /etc/etcd  && mkdir -p /etc/etcd/ssl "

##ssl工具下載
./sshTool -r cmd -u root  -h 192.168.122.100 -P 22 -k id_rsa  -c "cd /data/work && pwd && wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64"
./sshTool -r cmd -u root  -h 192.168.122.100 -P 22 -k id_rsa  -c "cd /data/work && pwd && wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64"
./sshTool -r cmd -u root  -h 192.168.122.100 -P 22 -k id_rsa  -c "cd /data/work && pwd && wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64"

##工具配置
./sshTool -r cmd -u root  -h 192.168.122.100 -P 22 -k id_rsa  -c "cd /data/work && mv cfssl_linux-amd64 /usr/local/bin/cfssl && mv cfssljson_linux-amd64 /usr/local/bin/cfssljson && mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo"


##配置ca请求文件
ca-csr.json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "GD",
      "L": "SZ",
      "O": "k8s",
      "OU": "system"
    }
  ],
  "ca": {
    "expiry": "87600h"
  }
}

注：
CN：Common Name，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法；
O：Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)

##创建ca证书
 cfssl gencert -initca ca-csr.json |cfssljson -bare ca

##配置ca证书策略
cat ca-config.json | jq .
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}

##配置etcd请求csr文件
cat  k8s-etcd-csr.json | jq .
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "192.168.122.100",
    "192.168.122.101",
    "192.168.122.102"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SZ",
      "L": "GD",
      "O": "k8s",
      "OU": "system"
    }
  ]
}

##生成证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes etcd-csr.json | cfssljson  -bare etcd

## 部署etcd集群
下载etcd软件包
wget https://github.com/etcd-io/etcd/releases/download/v3.4.13/etcd-v3.4.13-linux-amd64.tar.gz
tar -xf etcd-v3.4.13-linux-amd64.tar.gz
cp -p etcd-v3.4.13-linux-amd64/etcd* /usr/local/bin/
rsync -vaz etcd-v3.4.13-linux-amd64/etcd* k8s-master2:/usr/local/bin/
rsync -vaz etcd-v3.4.13-linux-amd64/etcd* k8s-master3:/usr/local/bin/


##创建配置文件
etcd.conf
#[Member]
ETCD_NAME="k8s-etcd1"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.122.100:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.122.100:2379,http://127.0.0.1:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.100:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.100:2379"
ETCD_INITIAL_CLUSTER="etcd1=https://192.168.122.100:2380,etcd2=https://192.168.122.101:2380,etcd3=https://192.168.122.102:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"


2
#[Member]
ETCD_NAME="k8s-etcd2"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.122.101:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.122.101:2379,http://127.0.0.1:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.101:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.101:2379"
ETCD_INITIAL_CLUSTER="etcd1=https://192.168.122.100:2380,etcd2=https://192.168.122.101:2380,etcd3=https://192.168.122.102:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

3
#[Member]
ETCD_NAME="k8s-etcd3"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.122.102:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.122.102:2379,http://127.0.0.1:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.102:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.102:2379"
ETCD_INITIAL_CLUSTER="etcd1=https://192.168.122.100:2380,etcd2=https://192.168.122.101:2380,etcd3=https://192.168.122.102:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"


注：
ETCD_NAME：节点名称，集群中唯一
ETCD_DATA_DIR：数据目录
ETCD_LISTEN_PEER_URLS：集群通信监听地址
ETCD_LISTEN_CLIENT_URLS：客户端访问监听地址
ETCD_INITIAL_ADVERTISE_PEER_URLS：集群通告地址
ETCD_ADVERTISE_CLIENT_URLS：客户端通告地址
ETCD_INITIAL_CLUSTER：集群节点地址
ETCD_INITIAL_CLUSTER_TOKEN：集群Token
ETCD_INITIAL_CLUSTER_STATE：加入集群的当前状态，new是新集群，existing表示加入已有集群


##配置啓動腳本
vim etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=-/etc/etcd/etcd.conf
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

##方式二：
无配置文件的启动方式

vim etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \
  --name=k8s-etcd1 \
  --data-dir=/var/lib/etcd/default.etcd \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --listen-peer-urls=https://192.168.122.100:2380 \
  --listen-client-urls=https://192.168.122.100:2379,http://127.0.0.1:2379 \
  --advertise-client-urls=https://192.168.122.100:2379 \
  --initial-advertise-peer-urls=https://192.168.122.100:2380 \
  --initial-cluster=etcd1=https://192.168.122.100:2380,etcd2=https://192.168.122.101:2380,etcd3=https://192.168.122.102:2380 \
  --initial-cluster-token=etcd-cluster \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target


###
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \
  --name=k8s-etcd2 \
  --data-dir=/var/lib/etcd/default.etcd \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --listen-peer-urls=https://192.168.122.101:2380 \
  --listen-client-urls=https://192.168.122.101:2379,http://127.0.0.1:2379 \
  --advertise-client-urls=https://192.168.122.101:2379 \
  --initial-advertise-peer-urls=https://192.168.122.101:2380 \
  --initial-cluster=etcd1=https://192.168.122.100:2380,etcd2=https://192.168.122.101:2380,etcd3=https://192.168.122.102:2380 \
  --initial-cluster-token=etcd-cluster \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target


##
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/local/bin/etcd \
  --name=k8s-etcd2 \
  --data-dir=/var/lib/etcd/default.etcd \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --listen-peer-urls=https://192.168.122.102:2380 \
  --listen-client-urls=https://192.168.122.102:2379,http://127.0.0.1:2379 \
  --advertise-client-urls=https://192.168.122.102:2379 \
  --initial-advertise-peer-urls=https://192.168.122.102:2380 \
  --initial-cluster=etcd1=https://192.168.122.100:2380,etcd2=https://192.168.122.101:2380,etcd3=https://192.168.122.102:2380 \
  --initial-cluster-token=etcd-cluster \
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target


##同步相关文件到各个节点

cp ca*.pem /etc/etcd/ssl/
cp etcd*.pem /etc/etcd/ssl/
cp etcd.conf /etc/etcd/
cp etcd.service /usr/lib/systemd/system/
for i in k8s-master2 k8s-master3;do rsync -vaz etcd.conf $i:/etc/etcd/;done
for i in k8s-master2 k8s-master3;do rsync -vaz etcd*.pem ca*.pem $i:/etc/etcd/ssl/;done
for i in k8s-master2 k8s-master3;do rsync -vaz etcd.service $i:/usr/lib/systemd/system/;done


注：master2和master3分别修改配置文件中etcd名字和ip，并创建目录 /var/lib/etcd/default.etcd

##启动etcd集群

mkdir -p /var/lib/etcd/default.etcd
systemctl daemon-reload
systemctl enable etcd.service
systemctl start etcd.service
systemctl status etcd


./sshTool -r cmd -u root -l -h 192.168.122.100-102 -P 22 -k id_rsa  -c "systemctl daemon-reload"
./sshTool -r cmd -u root -l -h 192.168.122.100-102 -P 22 -k id_rsa  -c "systemctl enable etcd.service"
./sshTool -r cmd -u root -l -h 192.168.122.100-102 -P 22 -k id_rsa  -c "systemctl start etcd.service"
./sshTool -r cmd -u root -l -h 192.168.122.100-102 -P 22 -k id_rsa  -c "systemctl status etcd"


##查看集群状态
ETCDCTL_API=3 /usr/local/bin/etcdctl --write-out=table --cacert=/etc/etcd/ssl/ca.pem --cert=/etc/etcd/ssl/etcd.pem --key=/etc/etcd/ssl/etcd-key.pem --endpoints=https://192.168.122.100:2379,https://192.168.122.101:2379,https://192.168.122.102:2379 endpoint health


##download k8s install packages
wget https://dl.k8s.io/v1.22/kubernetes-server-linux-amd64.tar.gz

3.4.1 下载安装包
wget https://dl.k8s.io/v1.20.1/kubernetes-server-linux-amd64.tar.gz
tar -xf kubernetes-server-linux-amd64.tar
cd kubernetes/server/bin/
[root@master1 bin]# cp kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
[root@master1 bin]# rsync -vaz kube-apiserver kube-controller-manager kube-scheduler kubectl k8s-master2:/usr/local/bin/
[root@master1 bin]# rsync -vaz kube-apiserver kube-controller-manager kube-scheduler kubectl k8s-master3:/usr/local/bin/
[root@master1 bin]# for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz kubelet kube-proxy $i:/usr/local/bin/;done
[root@master1 bin]# cd /data/work/

for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz kubelet kube-proxy $i:/usr/local/bin/;done
for i in k8s-master1 k8s-master2 k8s-master3; do rsync -vaz kubelet kube-proxy $i:/usr/local/bin/;done


3.4.2 创建工作目录
/etc/kubernetes/         # kubernetes组件配置文件存放目录
/etc/kubernetes/ssl     # kubernetes组件证书文件存放目录
/var/log/kubernetes      # kubernetes组件日志文件存放目录


./sshTool -r cmd -u root -l -h 192.168.122.100-105 -P 22 -k id_rsa  -c "mkdir -p /etc/kubernetes/ && mkdir -p /etc/kubernetes/ssl && mkdir /var/log/kubernetes"


##部署api-server
创建csr请求文件

vim kube-apiserver-csr.json
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "192.168.122.100",
    "192.168.122.101",
    "192.168.122.102",
    "192.168.122.103",
    "192.168.122.104",
    "192.168.122.106",
    "192.168.122.60",
    "192.168.122.200",
    "10.255.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "SZ",
      "L": "GD",
      "O": "k8s",
      "OU": "system"
    }
  ]
}

注：
如果 hosts 字段不为空则需要指定授权使用该证书的 IP 或域名列表。
由于该证书后续被 kubernetes master 集群使用，需要将master节点的IP都填上，同时还需要填写 service 网络的首个IP。(一般是 kube-apiserver 指定的 service-cluster-ip-range 网段的第一个IP，如 10.254.0.1)

##生成证书和token文件
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-apiserver-csr.json | cfssljson -bare kube-apiserver
cat > token.csv << EOF
$(head -c 16 /dev/urandom | od -An -t x | tr -d ' '),kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

##创建配置文件
KUBE_APISERVER_OPTS="--enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --anonymous-auth=false \
  --bind-address=192.168.122.100 \
  --secure-port=6443 \
  --advertise-address=192.168.122.100 \
  --insecure-port=0 \
  --authorization-mode=Node,RBAC \
  --runtime-config=api/all=true \
  --enable-bootstrap-token-auth \
  --service-cluster-ip-range=10.255.0.0/16 \
  --token-auth-file=/etc/kubernetes/token.csv \
  --service-node-port-range=30000-50000 \
  --tls-cert-file=/etc/kubernetes/ssl/kube-apiserver.pem  \
  --tls-private-key-file=/etc/kubernetes/ssl/kube-apiserver-key.pem \
  --client-ca-file=/etc/kubernetes/ssl/ca.pem \
  --kubelet-client-certificate=/etc/kubernetes/ssl/kube-apiserver.pem \
  --kubelet-client-key=/etc/kubernetes/ssl/kube-apiserver-key.pem \
  --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \
	--service-account-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  \      # 1.20以上版本必须有此参数
  --service-account-issuer=https://kubernetes.default.svc.cluster.local \   # 1.20以上版本必须有此参数
  --etcd-cafile=/etc/etcd/ssl/ca.pem \
  --etcd-certfile=/etc/etcd/ssl/etcd.pem \
  --etcd-keyfile=/etc/etcd/ssl/etcd-key.pem \
  --etcd-servers=https://192.168.122.100:2379,https://192.168.122.101:2379,https://192.168.122.102:2379 \
  --enable-swagger-ui=true \
  --allow-privileged=true \
  --apiserver-count=3 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/kube-apiserver-audit.log \
  --event-ttl=1h \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/var/log/kubernetes \
  --v=4"
注：
--logtostderr：启用日志
--v：日志等级
--log-dir：日志目录
--etcd-servers：etcd集群地址
--bind-address：监听地址
--secure-port：https安全端口
--advertise-address：集群通告地址
--allow-privileged：启用授权
--service-cluster-ip-range：Service虚拟IP地址段
--enable-admission-plugins：准入控制模块
--authorization-mode：认证授权，启用RBAC授权和节点自管理
--enable-bootstrap-token-auth：启用TLS bootstrap机制
--token-auth-file：bootstrap token文件
--service-node-port-range：Service nodeport类型默认分配端口范围
--kubelet-client-xxx：apiserver访问kubelet客户端证书
--tls-xxx-file：apiserver https证书
--etcd-xxxfile：连接Etcd集群证书
--audit-log-xxx：审计日志


##创建服务启动文件

vim kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=etcd.service
Wants=etcd.service

[Service]
EnvironmentFile=-/etc/kubernetes/kube-apiserver.conf
ExecStart=/usr/local/bin/kube-apiserver $KUBE_APISERVER_OPTS
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

##同步相关文件到各个节点

cp ca*.pem /etc/kubernetes/ssl/
cp kube-apiserver*.pem /etc/kubernetes/ssl/
cp token.csv /etc/kubernetes/
cp kube-apiserver.conf /etc/kubernetes/
cp kube-apiserver.service /usr/lib/systemd/system/
rsync -vaz kube-apiserver.service  k8s-master3:/usr/lib/systemd/system/
rsync -vaz token.csv k8s-master2:/etc/kubernetes/
rsync -vaz token.csv k8s-master3:/etc/kubernetes/
rsync -vaz kube-apiserver*.pem k8s-master2:/etc/kubernetes/ssl/     # 主要rsync同步文件，只能创建最后一级目录，如果ssl目录不存在会自动创建，但是上一级目录kubernetes必须存在
rsync -vaz kube-apiserver*.pem k8s-master3:/etc/kubernetes/ssl/
rsync -vaz ca*.pem k8s-master2:/etc/kubernetes/ssl/
rsync -vaz ca*.pem k8s-master3:/etc/kubernetes/ssl/
rsync -vaz kube-apiserver.conf k8s-master2:/etc/kubernetes/
rsync -vaz kube-apiserver.conf k8s-master3:/etc/kubernetes/
rsync -vaz kube-apiserver.service k8s-master2:/usr/lib/systemd/system/
rsync -vaz kube-apiserver.service k8s-master3:/usr/lib/systemd/system/


##启动服务

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver
测试
curl --insecure https://172.10.1.11:6443/
有返回说明启动正常


部署kubectl
创建csr请求文件

vim admin-csr.json
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "GD",
      "L": "SZ",
      "O": "system:masters",
      "OU": "system"
    }
  ]
}


说明：
后续 kube-apiserver 使用 RBAC 对客户端(如 kubelet、kube-proxy、Pod)请求进行授权；
kube-apiserver 预定义了一些 RBAC 使用的 RoleBindings，如 cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该 Role 授予了调用kube-apiserver 的所有 API的权限；
O指定该证书的 Group 为 system:masters，kubelet 使用该证书访问 kube-apiserver 时 ，由于证书被 CA 签名，所以认证通过，同时由于证书用户组为经过预授权的 system:masters，所以被授予访问所有 API 的权限；
注：
这个admin 证书，是将来生成管理员用的kube config 配置文件用的，现在我们一般建议使用RBAC 来对kubernetes 进行角色权限控制， kubernetes 将证书中的CN 字段 作为User， O 字段作为 Group；
"O": "system:masters", 必须是system:masters，否则后面kubectl create clusterrolebinding报错。

##生成证书

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
cp admin*.pem /etc/kubernetes/ssl/

cp admin*.pem /etc/kubernetes/ssl/
scp admin*.pem 192.168.122.101:/etc/kubernetes/ssl/
scp admin*.pem 192.168.122.102:/etc/kubernetes/ssl/

##创建kubeconfig配置文件
kubeconfig 为 kubectl 的配置文件，包含访问 apiserver 的所有信息，如 apiserver 地址、CA 证书和自身使用的证书


##设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.122.60:6443 --kubeconfig=kube.config
##设置客户端认证参数
kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=kube.config
##设置上下文参数
kubectl config set-context kubernetes --cluster=kubernetes --user=admin --kubeconfig=kube.config
##设置默认上下文
kubectl config use-context kubernetes --kubeconfig=kube.config
mkdir ~/.kube
cp kube.config ~/.kube/config
##授权kubernetes证书访问kubelet api权限
kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes




##同步kubectl配置文件到其他节点

rsync -vaz /root/.kube/config k8s-master2:/root/.kube/
rsync -vaz /root/.kube/config k8s-master3:/root/.kube/

##配置kubectl子命令补全

yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
kubectl completion bash > ~/.kube/completion.bash.inc
source '/root/.kube/completion.bash.inc'
source $HOME/.bash_profile


##部署kube-controller-manager
创建csr请求文件

vim kube-controller-manager-csr.json
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "192.168.122.100",
      "192.168.122.101",
      "192.168.122.102"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "GD",
        "L": "SZ",
        "O": "system:kube-controller-manager",
        "OU": "system"
      }
    ]
}


注：
hosts 列表包含所有 kube-controller-manager 节点 IP；
CN 为 system:kube-controller-manager、O 为 system:kube-controller-manager，kubernetes 内置的 ClusterRoleBindings system:kube-controller-manager 赋予 kube-controller-manager 工作所需的权限

##生成证书

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
ls kube-controller-manager*.pem

##创建kube-controller-manager的kubeconfig
#设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.122.60:6443 --kubeconfig=kube-controller-manager.kubeconfig
#设置客户端认证参数
kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-controller-manager.pem --client-key=kube-controller-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
#设置上下文参数
kubectl config set-context system:kube-controller-manager --cluster=kubernetes --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
#设置默认上下文
kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig



创建配置文件

vim kube-controller-manager.conf
KUBE_CONTROLLER_MANAGER_OPTS="--port=0 \
  --secure-port=10252 \
  --bind-address=127.0.0.1 \
  --kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \
  --service-cluster-ip-range=10.255.0.0/16 \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
  --cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \
  --allocate-node-cidrs=true \
  --cluster-cidr=10.0.0.0/16 \
  --experimental-cluster-signing-duration=87600h \
  --root-ca-file=/etc/kubernetes/ssl/ca.pem \
  --service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \
  --leader-elect=true \
  --feature-gates=RotateKubeletServerCertificate=true \
  --controllers=*,bootstrapsigner,tokencleaner \
  --horizontal-pod-autoscaler-use-rest-clients=true \
  --horizontal-pod-autoscaler-sync-period=10s \
  --tls-cert-file=/etc/kubernetes/ssl/kube-controller-manager.pem \
  --tls-private-key-file=/etc/kubernetes/ssl/kube-controller-manager-key.pem \
  --use-service-account-credentials=true \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/var/log/kubernetes \
  --v=2"

##创建启动文件

vim kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/kube-controller-manager.conf
ExecStart=/usr/local/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

##同步相关文件到各个节点

cp kube-controller-manager*.pem /etc/kubernetes/ssl/
cp kube-controller-manager.kubeconfig /etc/kubernetes/
cp kube-controller-manager.conf /etc/kubernetes/
cp kube-controller-manager.service /usr/lib/systemd/system/
rsync -vaz kube-controller-manager*.pem k8s-master2:/etc/kubernetes/ssl/
rsync -vaz kube-controller-manager*.pem k8s-master3:/etc/kubernetes/ssl/
rsync -vaz kube-controller-manager.kubeconfig kube-controller-manager.conf k8s-master2:/etc/kubernetes/
rsync -vaz kube-controller-manager.kubeconfig kube-controller-manager.conf k8s-master3:/etc/kubernetes/
rsync -vaz kube-controller-manager.service k8s-master2:/usr/lib/systemd/system/
rsync -vaz kube-controller-manager.service k8s-master3:/usr/lib/systemd/system/


##启动服务

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager

##部署kube-scheduler
创建csr请求文件

vim kube-scheduler-csr.json
{
    "CN": "system:kube-scheduler",
    "hosts": [
      "127.0.0.1",
      "192.168.122.100",
      "192.168.122.101",
      "192.168.122.102"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "GD",
        "L": "SZ",
        "O": "system:kube-scheduler",
        "OU": "system"
      }
    ]
}
注：
hosts 列表包含所有 kube-scheduler 节点 IP；
CN 为 system:kube-scheduler、O 为 system:kube-scheduler，kubernetes 内置的 ClusterRoleBindings system:kube-scheduler 将赋予 kube-scheduler 工作所需的权限。

##生成证书

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
ls kube-scheduler*.pem

##创建kube-scheduler的kubeconfig

#设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.122.60:6443 --kubeconfig=kube-scheduler.kubeconfig
#设置客户端认证参数
kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig
#设置上下文参数
kubectl config set-context system:kube-scheduler --cluster=kubernetes --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
#设置默认上下文
kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig

##创建配置文件

vim kube-scheduler.conf
KUBE_SCHEDULER_OPTS="--address=127.0.0.1 \
--kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
--leader-elect=true \
--alsologtostderr=true \
--logtostderr=false \
--log-dir=/var/log/kubernetes \
--v=2"

##创建服务启动文件

vim kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/kube-scheduler.conf
ExecStart=/usr/local/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target


##同步相关文件到各个节点

cp kube-scheduler*.pem /etc/kubernetes/ssl/
cp kube-scheduler.kubeconfig /etc/kubernetes/
cp kube-scheduler.conf /etc/kubernetes/
cp kube-scheduler.service /usr/lib/systemd/system/
rsync -vaz kube-scheduler*.pem k8s-master2:/etc/kubernetes/ssl/
rsync -vaz kube-scheduler*.pem k8s-master3:/etc/kubernetes/ssl/
rsync -vaz kube-scheduler.kubeconfig kube-scheduler.conf k8s-master2:/etc/kubernetes/
rsync -vaz kube-scheduler.kubeconfig kube-scheduler.conf k8s-master3:/etc/kubernetes/
rsync -vaz kube-scheduler.service k8s-master2:/usr/lib/systemd/system/
rsync -vaz kube-scheduler.service k8s-master3:/usr/lib/systemd/system/



##启动服务

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler
systemctl status kube-scheduler

##部署docker
在三个work节点上安装
安装docker

wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum install -y docker-ce --allowerasing
systemctl enable docker
systemctl start docker
docker --version

##修改docker源和驱动

cat > /etc/docker/daemon.json << EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "registry-mirrors": [
        "https://1nj0zren.mirror.aliyuncs.com",
        "https://kfwkfulq.mirror.aliyuncs.com",
        "https://2lqq34jg.mirror.aliyuncs.com",
        "https://pee6w651.mirror.aliyuncs.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "http://f1361db2.m.daocloud.io",
        "https://registry.docker-cn.com"
    ]
}
EOF
systemctl restart docker
docker info | grep "Cgroup Driver"


##下载依赖镜像

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2

docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.7.0
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.7.0 k8s.gcr.io/coredns:1.7.0
docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.7.0

##3.4.8 部署kubelet
以下操作在master1上操作
创建kubelet-bootstrap.kubeconfig

BOOTSTRAP_TOKEN=$(awk -F "," '{print $1}' /etc/kubernetes/token.csv)
#设置集群参数
kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.122.60:6443 --kubeconfig=kubelet-bootstrap.kubeconfig
#设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=kubelet-bootstrap.kubeconfig
#设置上下文参数
kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap --kubeconfig=kubelet-bootstrap.kubeconfig
#设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap.kubeconfig
#创建角色绑定
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap


##创建配置文件

 vim kubelet.json
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "authentication": {
    "x509": {
      "clientCAFile": "/etc/kubernetes/ssl/ca.pem"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "address": "192.168.122.103",
  "port": 10250,
  "readOnlyPort": 10255,
  "cgroupDriver": "cgroupfs",                     # 如果docker的驱动为systemd，处修改为systemd。此处设置很重要，否则后面node节点无法加入到集群
  "hairpinMode": "promiscuous-bridge",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletClientCertificate": true,
    "RotateKubeletServerCertificate": true
  },
  "clusterDomain": "cluster.local.",
  "clusterDNS": ["10.255.0.2"]
}


##创建启动文件

vim kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=/var/lib/kubelet
ExecStart=/usr/local/bin/kubelet \
  --bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig \
  --cert-dir=/etc/kubernetes/ssl \
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
  --config=/etc/kubernetes/kubelet.json \
  --network-plugin=cni \
  --pod-infra-container-image=k8s.gcr.io/pause:3.2 \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/var/log/kubernetes \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target


注：
–hostname-override：显示名称，集群中唯一
–network-plugin：启用CNI
–kubeconfig：空路径，会自动生成，后面用于连接apiserver
–bootstrap-kubeconfig：首次启动向apiserver申请证书
–config：配置参数文件
–cert-dir：kubelet证书生成目录
–pod-infra-container-image：管理Pod网络容器的镜像

##同步相关文件到各个节点

cp kubelet-bootstrap.kubeconfig /etc/kubernetes/
cp kubelet.json /etc/kubernetes/
cp kubelet.service /usr/lib/systemd/system/
#以上步骤，如果master节点不安装kubelet，则不用执行
rsync -vaz kubelet.json k8s-master2:/etc/kubernetes/
rsync -vaz kubelet.json k8s-master3:/etc/kubernetes/
for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz kubelet-bootstrap.kubeconfig kubelet.json $i:/etc/kubernetes/;done
for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz ca.pem $i:/etc/kubernetes/ssl/;done
for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz kubelet.service $i:/usr/lib/systemd/system/;done


for i in k8s-master2 k8s-master3 ;do rsync -vaz kubelet-bootstrap.kubeconfig kubelet.json $i:/etc/kubernetes/;done
for i in k8s-master2 k8s-master3 ;do rsync -vaz ca.pem $i:/etc/kubernetes/ssl/;done
for i in k8s-master2 k8s-master3 ;do rsync -vaz kubelet.service $i:/usr/lib/systemd/system/;done


##注：kubelete.json配置文件address改为各个节点的ip地址
启动服务
各个work节点上操作

mkdir /var/lib/kubelet
mkdir /var/log/kubernetes
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet

##确认kubelet服务启动成功后，接着到master上Approve一下bootstrap请求。执行如下命令可以看到三个worker节点分别发送了三个 CSR 请求：

 kubectl get csr


 [root@master1 work]# kubectl certificate approve node-csr-HlX3cExsZohWsu8Dd6Rp_ztFejmMdpzvti_qgxo4SAQ
 [root@master1 work]# kubectl certificate approve node-csr-oykYfnH_coRF2PLJH4fOHlGznOZUBPDg5BPZXDo2wgk
 [root@master1 work]# kubectl certificate approve node-csr-ytRB2fikhL6dykcekGg4BdD87o-zw9WPU44SZ1nFT50
 [root@master1 work]# kubectl get csr
 [root@master1 work]# kubectl get nodes



 ##3.4.9 部署kube-proxy
创建csr请求文件

[root@master1 work]# vim kube-proxy-csr.json
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "GD",
      "L": "SZ",
      "O": "k8s",
      "OU": "system"
    }
  ]
}

##生成证书

生成证书

[root@master1 work]# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
[root@master1 work]# ls kube-proxy*.pem
创建kubeconfig文件

kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.122.60:6443 --kubeconfig=kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


##创建kube-proxy配置文件

[root@master1 work]# vim kube-proxy.yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 192.168.122.100
clientConnection:
  kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig
clusterCIDR: 172.168.0.0/16                           # 此处网段必须与网络组件网段保持一致，否则部署网络组件时会报错
healthzBindAddress: 192.168.122.100:10256
kind: KubeProxyConfiguration
metricsBindAddress: 192.168.122.100:10249
mode: "ipvs"


##创建服务启动文件

[root@master1 work]# vim kube-proxy.service
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target

[Service]
WorkingDirectory=/var/lib/kube-proxy
ExecStart=/usr/local/bin/kube-proxy \
  --config=/etc/kubernetes/kube-proxy.yaml \
  --alsologtostderr=true \
  --logtostderr=false \
  --log-dir=/var/log/kubernetes \
  --v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target


##同步文件到各个节点

cp kube-proxy*.pem /etc/kubernetes/ssl/
cp kube-proxy.kubeconfig kube-proxy.yaml /etc/kubernetes/
cp kube-proxy.service /usr/lib/systemd/system/
#master节点不安装kube-proxy，则以上步骤不用执行
for i in k8s-master2 k8s-master3;do rsync -vaz kube-proxy.kubeconfig kube-proxy.yaml $i:/etc/kubernetes/;done
for i in k8s-master2 k8s-master3;do rsync -vaz kube-proxy.service $i:/usr/lib/systemd/system/;done

for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz kube-proxy.kubeconfig kube-proxy.yaml $i:/etc/kubernetes/;done
for i in k8s-node1 k8s-node2 k8s-node3;do rsync -vaz kube-proxy.service $i:/usr/lib/systemd/system/;done


##启动服务

mkdir -p /var/lib/kube-proxy
systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy
systemctl status kube-proxy


##配置网络组件
[root@master1 work]# wget https://docs.projectcalico.org/v3.14/manifests/calico.yaml
[root@master1 work]# kubectl apply -f calico.yaml


kubectl  get pod -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-6dfcd885bf-bqqxt   0/1     Running   0          94s
kube-system   calico-node-2slr5                          0/1     Running   0          95s
kube-system   calico-node-bjjdj                          0/1     Running   0          95s
kube-system   calico-node-fkg5k                          0/1     Running   0          95s
kube-system   calico-node-nd2ks                          0/1     Running   0          95s
kube-system   calico-node-rz685                          0/1     Running   0          95s
kube-system   calico-node-x9gkf                          0/1     Pending   0          95s


##部署coredns
下载coredns yaml文件：https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
修改yaml文件:
kubernetes cluster.local in-addr.arpa ip6.arpa
forward . /etc/resolv.conf
clusterIP为：10.255.0.2（kubelet配置文件中的clusterDNS）

coredns.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
 name: coredns
 namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
 labels:
   kubernetes.io/bootstrapping: rbac-defaults
 name: system:coredns
rules:
 - apiGroups:
   - ""
   resources:
   - endpoints
   - services
   - pods
   - namespaces
   verbs:
   - list
   - watch
 - apiGroups:
   - discovery.k8s.io
   resources:
   - endpointslices
   verbs:
   - list
   - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
 annotations:
   rbac.authorization.kubernetes.io/autoupdate: "true"
 labels:
   kubernetes.io/bootstrapping: rbac-defaults
 name: system:coredns
roleRef:
 apiGroup: rbac.authorization.k8s.io
 kind: ClusterRole
 name: system:coredns
subjects:
- kind: ServiceAccount
 name: coredns
 namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
 name: coredns
 namespace: kube-system
data:
 Corefile: |
   .:53 {
       errors
       health {
         lameduck 5s
       }
       ready
       kubernetes cluster.local  in-addr.arpa ip6.arpa  {
         fallthrough in-addr.arpa ip6.arpa
       }
       prometheus :9153
       forward . /etc/resolv.conf {
         max_concurrent 1000
       }
       cache 30
       loop
       reload
       loadbalance
   }STUBDOMAINS
---
apiVersion: apps/v1
kind: Deployment
metadata:
 name: coredns
 namespace: kube-system
 labels:
   k8s-app: kube-dns
   kubernetes.io/name: "CoreDNS"
spec:
 # replicas: not specified here:
 # 1. Default is 1.
 # 2. Will be tuned in real time if DNS horizontal auto-scaling is turned on.
 strategy:
   type: RollingUpdate
   rollingUpdate:
     maxUnavailable: 1
 selector:
   matchLabels:
     k8s-app: kube-dns
 template:
   metadata:
     labels:
       k8s-app: kube-dns
   spec:
     priorityClassName: system-cluster-critical
     serviceAccountName: coredns
     tolerations:
       - key: "CriticalAddonsOnly"
         operator: "Exists"
     nodeSelector:
       kubernetes.io/os: linux
     affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                  - key: k8s-app
                    operator: In
                    values: ["kube-dns"]
              topologyKey: kubernetes.io/hostname
     containers:
     - name: coredns
       image: coredns/coredns:1.8.4
       imagePullPolicy: IfNotPresent
       resources:
         limits:
           memory: 170Mi
         requests:
           cpu: 100m
           memory: 70Mi
       args: [ "-conf", "/etc/coredns/Corefile" ]
       volumeMounts:
       - name: config-volume
         mountPath: /etc/coredns
         readOnly: true
       ports:
       - containerPort: 53
         name: dns
         protocol: UDP
       - containerPort: 53
         name: dns-tcp
         protocol: TCP
       - containerPort: 9153
         name: metrics
         protocol: TCP
       securityContext:
         allowPrivilegeEscalation: false
         capabilities:
           add:
           - NET_BIND_SERVICE
           drop:
           - all
         readOnlyRootFilesystem: true
       livenessProbe:
         httpGet:
           path: /health
           port: 8080
           scheme: HTTP
         initialDelaySeconds: 60
         timeoutSeconds: 5
         successThreshold: 1
         failureThreshold: 5
       readinessProbe:
         httpGet:
           path: /ready
           port: 8181
           scheme: HTTP
     dnsPolicy: Default
     volumes:
       - name: config-volume
         configMap:
           name: coredns
           items:
           - key: Corefile
             path: Corefile
---
apiVersion: v1
kind: Service
metadata:
 name: kube-dns
 namespace: kube-system
 annotations:
   prometheus.io/port: "9153"
   prometheus.io/scrape: "true"
 labels:
   k8s-app: kube-dns
   kubernetes.io/cluster-service: "true"
   kubernetes.io/name: "CoreDNS"
spec:
 selector:
   k8s-app: kube-dns
 clusterIP: 10.255.0.2
 ports:
 - name: dns
   port: 53
   protocol: UDP
 - name: dns-tcp
   port: 53
   protocol: TCP
 - name: metrics
   port: 9153
   protocol: TCP

kubectl apply -f coredns.yaml

## 验证
3.5.1 部署nginx
[root@master1 ~]# vim nginx.yaml
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-controller
spec:
  replicas: 2
  selector:
    name: nginx
  template:
    metadata:
      labels:
        name: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.19.6
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-nodeport
spec:
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30001
      protocol: TCP
  type: NodePort
  selector:
    name: nginx
[root@master1 ~]# kubectl apply -f nginx.yaml
[root@master1 ~]# kubectl get svc
[root@master1 ~]# kubectl get pods

