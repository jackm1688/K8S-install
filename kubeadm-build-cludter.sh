###clone 5 mc
mkdir -p /home/lemon/ssd_data_lv/kvm/kubedm/k8s-{m01,m02,m03,n01,n02}
virt-clone --original centos8 --name k8s-m01 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-m01/k8s-m01.img --check disk_size=off
virt-clone --original centos8 --name k8s-m02 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-m02/k8s-m02.img --check disk_size=off
virt-clone --original centos8 --name k8s-m03 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-m03/k8s-m03.img --check disk_size=off
virt-clone --original centos8 --name k8s-n01 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-n01/k8s-n01.img --check disk_size=off
virt-clone --original centos8 --name k8s-n02 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-n02/k8s-n02.img --check disk_size=off

virt-clone --original centos8 --name k8s-ng1 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-ng1/k8s-ng1.img --check disk_size=off
virt-clone --original centos8 --name k8s-ng2 --file  /home/lemon/ssd_data_lv/kvm/kubedm/k8s-ng2/k8s-ng2.img --check disk_size=off

##get mac and binding
<host mac='52:54:00:3c:fa:87' name='k8s-m01' ip='192.168.122.40'/>
<host mac='52:54:00:fa:e5:81' name='k8s-m02' ip='192.168.122.41'/>
<host mac='52:54:00:2a:e0:ee' name='k8s-m03' ip='192.168.122.42'/>
<host mac='52:54:00:0e:ac:1d' name='k8s-n01' ip='192.168.122.43'/>
<host mac='52:54:00:f6:0c:46' name='k8s-n02' ip='192.168.122.44'/>
<host mac='52:54:00:9c:b8:68' name='k8s-ng1' ip='192.168.122.45'/>
<host mac='52:54:00:f6:f6:2c' name='k8s-ng2' ip='192.168.122.46'/>

##start vm
for m in k8s-m01 k8s-m02 k8s-m03 k8s-n01 k8s-n02  k8s-ng1 k8s-ng2; do echo $m && virsh start $m; done;
for m in k8s-m01 k8s-m02 k8s-m03 k8s-n01 k8s-n02   k8s-ng1 k8s-ng2; do echo $m && virsh destroy  $m; done;

192.168.122.40 k8s-m01
192.168.122.41 k8s-m02
192.168.122.42 k8s-m03
192.168.122.43 k8s-n01
192.168.122.44 k8s-n02
192.168.122.45 k8s-ng2
192.168.122.46 k8s-ng2

#time zone
rm -f /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

##close swap
vim /etc/fstab

/dev/mapper/cl-root     /                       xfs     defaults        0 0
UUID=7ffd29ec-33bd-4213-9965-e53200910233 /boot                   xfs     defaults        0 0
/dev/mapper/cl-home     /home                   xfs     defaults        0 0
#/dev/mapper/cl-swap     none                    swap    defaults        0 0

##install docker

# 安装yum-utils
yum install -y yum-utils
# 添加Docker软件源
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
# 安装docker-ce,docker-ce-cli,containerd.io
yum install docker-ce docker-ce-cli containerd.io --allowerasing

# 安装完成后启动docker
systemctl start docker
# 启动docker后设置Dokcer以后开机自启动
systemctl enable docker


##配置docker加速
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

##close FIREWALL
systemctl disable firewalld && systemctl stop firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config


##时间同步
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
sudo modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
lsmod | grep ip_vs
lsmod | grep nf_conntrack_ipv4
yum install -y ipvsadm


将Kubernetes安装源改为阿里云，方便国内网络环境安装
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

##kubeadm功能
ubeadm工具功能：
•kubeadm init：初始化一个Master节点
•kubeadm join：将工作节点加入集群
•kubeadm upgrade：升级K8s版本
•kubeadm token：管理 kubeadm join 使用的令牌
•kubeadm reset：清空 kubeadm init 或者 kubeadm join 对主机所做的任何更改
•kubeadm version：打印 kubeadm 版本
•kubeadm alpha：预览可用的新功能


##寫host文件(每个节点都添加，etcd和k8s master部署在一起)
192.168.122.40 k8s-m01 etcd-01
192.168.122.41 k8s-m02 etcd-02
192.168.122.42 k8s-m03 etcd-03
192.168.122.43 k8s-n01
192.168.122.44 k8s-n02
192.168.122.45 k8s-ng2
192.168.122.46 k8s-ng2



##添加阿里云YUM软件源
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


#安装haproxy(k8s-ng01,k8s-ng02)

yum install haproxy -y
修改haproxy配置(k8s-ng01,k8s-ng02,the smae config file )#

cat << EOF > /etc/haproxy/haproxy.cfg
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    tcp
    log                     global
    retries                 3
    timeout connect         10s
    timeout client          1m
    timeout server          1m

frontend kube-apiserver
    bind *:6443 # 指定前端端口
    mode tcp
    default_backend master

backend master # 指定后端机器及端口，负载方式为轮询
    balance roundrobin
    server k8s-m01  192.168.122.40:6443 check maxconn 2000
    server k8s-m02  192.168.122.41:6443 check maxconn 2000
    server k8s-m03  192.168.122.42:6443 check maxconn 2000
EOF
开机默认启动haproxy，开启服务#

systemctl enable haproxy
systemctl start haproxy

#install keepalived
yum -y install keepalived

##check haproxy
mkdir /usr/local/script

cat > /usr/local/script/check_haproxy.sh  <<EOF
#!/bin/bash
if [ $(ps -C haproxy --no-header | wc -l) -eq 0 ];then
        echo "systemctl start haproxy" > /tmp/run.txt
        systemctl start haproxy
        return 1
fi

if [ $(ps -C haproxy --no-header | wc -l) -eq 0 ];then
       echo "systemctl stop keepalived" > /tmp/run.txt
       systemctl stop keepalived
       return 1
fi
EOF

#定义master节点的keepalived配置
cat << EOF  > /etc/keepalived/keepalived.conf
global_defs {
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
   vrrp_skip_check_adv_addr
   vrrp_strict
   vrrp_garp_interval 0
   vrrp_gna_interval 0
   vrrp_iptables #禁止keepalived启动生成默认的iptables规则
   vrrp_mcast_group4 224.17.17.17  #定义主备节点通过组播地址进行通告状态
}

vrrp_script chk_down {
        script "/bin/bash  -c '[[ -f /etc/keepalived/down ]]' && exit 1 || exit 0"
        interval 1
        weight -10
}

vrrp_script chk_haproxy {  #调用外部的辅助脚本进行资源监控,并根据监控的结果状态能实现优先动态调整
        script "/usr/bin/killall -0 haproxy && exit 0 || exit 1"
		#script指令：先定义一个执行脚本，如果脚本执行结果状态为0则不操作后续步奏，如果状态为非0，则执行相应的操作
        interval 1     #每秒检查执行一次
        weight -10    #如果脚本执行结果为非0 ，则keepalived的优先级减去10
        fall 2    #如果连续两次检测为错误状态则认为服务部可用
        rise 1    #检测一次成功就认为服务正常
    }

vrrp_instance VI_1 {   #配置虚拟路由实例
    state MASTER      #定义该节点为MASTER节点
    interface enp1s0   #定义VIP绑定的物理网卡
    virtual_router_id 55   #设置虚路由拟路由id，同一集群的节点群必须相同
    priority 100           #设定优先级
    advert_int 1        #设定master与backup之间vrrp通告的时间间隔，单位是秒
    authentication {  #定义验证方式与密码
        auth_type PASS
        auth_pass 12345678  #密码最长8位
    }
    virtual_ipaddress {    #定义虚拟路由IP,也是对外接收请求的ip
        192.168.122.47
    }

track_script {  #用于追踪脚本执行状态，定义在vrrp_instance段中
        chk_haproxy

   }
}
EOF


###定义BACKUP节点Keepalived配置
##BACKUP节点与MASTER节点定义大致相同，只有BACKUP节点的角色，优先级需要修改，其他都不需要改动
! Configuration File for keepalived

global_defs {
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
   vrrp_skip_check_adv_addr
   vrrp_strict
   vrrp_garp_interval 0
   vrrp_gna_interval 0
   vrrp_iptables
   vrrp_mcast_group4 224.17.17.17
}



vrrp_script chk_down {
        script "/bin/bash -c '[[ -f /etc/keepalived/down ]]' && exit 1 || exit 0"
        interval 1
        weight -10
}

vrrp_script chk_haproxy {
        script "/usr/bin/killall -0 haproxy && exit 0 || exit 1"
        interval 1
        weight -10
        fall 2
        rise 1
    }


vrrp_instance VI_1 {
    state BACKUP
    interface enp1s0
    virtual_router_id 55
    priority 95
    advert_int 1
#    nopreempt
    authentication {
        auth_type PASS
        auth_pass 12345678
    }
    virtual_ipaddress {
        192.168.122.47
    }

track_script {
        chk_haproxy

   }
}


##start keepalived
systemctl enable keepalived
systemctl start keepalived
systemctl start haproxy



###每个节点生成ssh证书，并与master1建立双向信任关系
ssh-keygen -t rsa
将其他节点上的/root/.ssh/id_rsa.pub文件内容写到master1上的/root/.ssh/authorized_keys文件中
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC69BQdSgpt+ns2DIJp8p+/dD07x+qfMxz1DA4sc62PcqHNyQont1iRkvfgLLmKg8aO8mcI9laj69qmLfDYADULh/VL+ar/JO570JXjHM2cH8e86cllsMWYaapHC6OawFDI+BWpuyvqBlsoyDIK2JVCZ1rUhkfPQQDkrgQdIp1Ku5MCqGxhSz8+i9ip9aRjg7eG9g9dV9Gr/gA4d6Rdk6GSXfQAVGR+4T9aosjEG/YtGpzxmwM8xAOOwFTTYEQavtWh7saMD9bvar3peeM4shnvxkN03X6PiOHfdd6t6DL70RNrAm3Bg5lZitu4A8j4iFvzibEnJtyDoZVZVuGs8RIxYOifZzZJ264HlL7d+rrJz0AxU3K3YXVf5yhrVCTqwhmpfEZm9pO3jMYf/ywswewyaUikgkuPVjsg0YOmFd5lVof1ZvLMbkrgRKZ1VvPDAF6JV62gZLkeVER/FJ4XuZ0h317BPMN0BRZS3pAUaYyZzHeuPBRVRGJLeiYvLAEwIyM= root@k8s-m02" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjPFUZi/qmS9U5eHUomDrcx5qdPqAszMaQJawNnK8nSn6snICM7W/Pkk1HI4SJ+HvDmyvO1gTNtRTpNb9GdU3mxj5zJaCCA/ETcfKwMt8dKiQ+T/AOnc0l0cYLdvjNTvQwojc7GkpVJbfxUcUdR/z731d0WRChO893MzUlrxpKZUZrWi+ly1xUHmxofLQBsjorxJofjG32T+tcLXmthMFRR2f/vnZdIfVcCGh1cIvCzyvTg92DyztnILF+vybEVgDbd8eWmIQBkWoVJbQprM7IUeAalwx2BAxSYrf9oNRLIL1Uv0P22CEbiA6x+Ojd56Rp13MRSUN2TA1dz6WLoSP1YcU6l7n4TDTULOgUROIGvobSSBdkQFFKGNxGuTM3Z2BiW58+sy10855gRHKwXiakmWhf9NCWcCwvRs9J4moQObwc1ct2pkNkJ/473uz+e5rcO4fcB1spRdWSRJkI+EFK3u+4Lh/3pWLVtPdLcHnnetELT/f9wBgvb+i20mJB5Q8= root@k8s-m03" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDC0P06HwtpM0W3RS+msMMKo6m+A9UjVyJrP9z5/10bePcqC6BWyxgkYdfgAw9lrvqZBetZ2LBCoSKqntZL9IhvEwN50DGO1zLu9Bsce0lJ8ieqPmAuL1BkwFcsQYVHI17ZhL//E/QX7a2zb0d17TwBmv988DkOScq9n1DIyZ9NDCCvhZVGcXYoy+hPI4SAQ5hUNmQBeQX6xoica2Ejggu+bzBkS6kMsrvrEkbigT/klmEHvrob3X2ptfFHum/KoolPk7OSP+6v6S4QhIVob3tDrlivcVVFzFfi/jsUpkmdqBpOkcQoW0mVtLQj+dTA0kjfod9B7Qadmukc+gCZ4Al1j1CInZYtTVFmG5Vsyl73Hs77VxnUztkWgCpLWtHWoJOlMF83XF0VnVJ1OUehQfnQOgpxanAAHseaDHmfuAB3t+tPf25SUknPl9O2J2c8CKdGGy/hrz/vOQ2BQyI/VyK5U3FZXRZ1Dis57kzTlYq8xsg3zjzX3AHDgq8Pi2KAK1U= root@k8s-n01" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDP3QYiszRnEeYy0RN9JRpVS+tJwFWAjjoCtE3L+zuqhyKrQwL3OV9q+fUegzda584esrkr1jUbcEYSmDz+4DG3yAvGhkIqqVK1YDgelUM0jjf9if2XhpI1cx8MgJLqSWL4F70K4/DOFuqp9L0QvnecAnJXCwtV/osWPahYB6REED/oor8bumGQx3j+dlcPTBs0y7jknmnOqA2pk+HjnGlQvBCEJcDJ2QG7PK++CtbJZ5i/0mCfdROCRI05KhzNI/wTzkwARFCGJteMZ9EpxZg/6AY0B+eGXzMxNoxyyZLn/Ue6k0ddrdSM8chEYs30eldPLDlSXxmzNjQA5NLWXcAPS2F7oLSg9zlVHspM7l3zk538WVyX2ByUfpYAeQaF5DWix8TM76zfCZMtVcY6/1j/12oZcXD44a694hbhOv1++ZXB/Njyz0AI/NjbjkNf+tGgh82+7NsshNQu19ggr3yQlaCf2dFmZs0uDBzkZ48Dmz4BVhnvsv4XPiFB2KyR+m8= root@k8s-n02" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjrlDyFh+TOS1VPv6KwicN5wIXCMB/KLsQTMZLDUbh4vNSjDbLR/f5Twx5NWbIBYZ071TDv7i0FpyLnQZCy0hslQ2X2vpIyFr+52fqrr8TzwkI3jW8/I4AXmINNRdsUhc+OHqDoqLKJRwUNsTNO5CEwBKidppjv3WHt8T7FEGEdMxFdsfPewJAf7Q1W2kmIljgZhV1NjxxPsSQrXv9hwW5s2niPd7/IoLmoySKRhyZKuk5ieN+0WigXc/+tGs2qSJOAcANkJboWdGzsn2qAni9MD+l/79dc4ArxyGGM9Zzk09Sm40NRyt8SDgFv6sIUt4J5Z2HIYBPTihQ9F3HJ7yOloK1HOf2zLwLXmdnm9x1/04ZT68ssSWyFu8br0XSRRmw5yeggojTPfYtqvEIG3cWLsXoKpdiHO1Q/ZvDRviACmuGcFl3jsq8bJoEKygE/V6Zg/uQtogDf9X4w8DC/2CYN04rr6fQqn2FQC6oh0tCk8rFGOAbXJAndp0QZsGBT0U= root@k8s-ng1" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDF4eeBSNxmLaWCkxJvDIOJDlQu98F9H0DhHjXfAg9lLAuhvb+26T0IC5mLIS8M6ZchbpK9zUUiQMfSIyNeh0rzj+sPHLePciY53TT2Jg4lobFUHMzdE4OOYdQ92GgbnEDABJuoVerSJuhPKUAE3UnVaWlIasffXIF62N0z4Z1AP6o7EMnhVyKkSfbEqoM7Q7mjRbS3lCbPD9W3dTVEeN6cFzlPz5ApwaG3V7/Z9JfOtK9rEe2BqISnQQDW8X62Kx5dPLdzc7yO6qxEIyFbvApfmpzrmadqQIkMUITz/eHNh71icsbPqrWJcwQLRwE4A4yv/AWYLVqgCznksrwS10aGvOQDCHIThw8U6Bi93XcKop9PQa9NHHOWVzZ2R4q+W4M3r8W+SiZToxMBR7IFVYNtYUMbpEjxIeTAqi5tpIYKG7wL4d7qxBnsl6FsZU02qA/1E3wt+p4l92qLhrCO5ho343CYQDYA9qUGKwHVkkEwgk/tHNhJBZHl9PEoAMovQgM= root@k8s-ng2" >> /root/.ssh/authorized_keys


将mster1节点上的/root/.ssh/id_rsa.pub文件内容写到其他上的/root/.ssh/authorized_keys文件中
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDO0Jezo1NlZ5WhQG8MPsc+2VnmftUyKmM798WRm0B5DkG0nlCrApxtYF2E3q3tecAUHjimxAsm9woPpCVmLvWgLcX7Pn5S4pIg6dPsgWJXVFQy0x6XQN/xOfq0demYinpM+GSPLH/GI1HJ07IL8Hnd/y2HiQ3BndVL+0ippXVgDFO5ftikFUI0Zrk6Pv45xzK4l9MkXnwhZXINfMH9fe0EAocwNcTnSvwo6WTUGPsL22xdbeISouwzUuSIiq+pxjm2MUs/VFHch7F7xKB87LXxIFwEa3cIuF3QnogMJNYFKf4PI/6RenH6hTyGKo5YHEOkW/Wk+dvKxQ69N7YJJrxosPvMhtOzJ8TVffEMhcvl/eHIT4Rvu8MkKb1A2SOyZ5ecQJNslUKnvBV2zUIkZIjAJUcACezK1vG7DkFmLrS4tCtEQ7M9WoA+Y6iQ5TGc+prrU+txIWpcWU+ssBK7exJJlqytU38jjCMrPNB/zgNiyqQzy/AcXkyQZCbYXjFntyk= root@k8s-m01" >> /root/.ssh/authorized_keys
##install kubelet-1.21.0 kubeadm-1.21.0 kubectl-1.21.0

##download ssl tool
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo


##create etcd ca file
mkdir /root/etcd_tls
cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "etcd": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat > ca-csr.json << EOF
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "GDSZ",
            "ST": "GDSZ"
        }
    ]
}
EOF
生成证书：
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
会生成ca.pem和ca-key.pem文件。
##使用自签CA签发Etcd HTTPS证书
创建证书申请文件：
cat > server-csr.json << EOF
{
    "CN": "etcd",
    "hosts": [
    "192.168.122.40",
    "192.168.122.41",
    "192.168.122.42"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "GDSZ",
            "ST": "GDSZ"
        }
    ]
}
EOF
注：上述文件hosts字段中IP为所有etcd节点的集群内部通信IP，一个都不能少！为了方便后期扩容可以多写几个预留的IP。
生成证书：
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd server-csr.json | cfssljson -bare etcd-server
会生成etcd-server.pem和etcd-server-key.pem文件。

##从Github下载二进制文件
下载地址：https://github.com/etcd-io/etcd/releases/download/v3.4.9/etcd-v3.4.9-linux-amd64.tar.gz
##部署Etcd集群
以下在节点1上操作，为简化操作，待会将节点1生成的所有文件拷贝到节点2和节点3。
##创建工作目录并解压二进制包
mkdir /opt/etcd/{bin,cfg,ssl} -p
tar zxvf etcd-v3.4.9-linux-amd64.tar.gz
cp etcd-v3.4.9-linux-amd64/{etcdctl,etcd}  /usr/local/bin/ && chmod +x /usr/local/bin/{etcdctl,etcd}
##创建etcd配置文件
mkdir /opt/etcd/cfg/ -p
mkdir /var/lib/etcd/
mkdir /opt/etcd/ssl/

#####拷贝刚才生成的证书,把刚才生成的证书拷贝到配置文件中的路径：
cd /root/etcd_tls
for node in k8s-m01 k8s-m02 k8s-m03; do scp  ca.pem ca-key.pem etcd-server* $node:/opt/etcd/ssl/; done
cd ..



cat > /opt/etcd/cfg/etcd.conf << EOF
#[Member]
ETCD_NAME="etcd-01"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.122.40:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.122.40:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.40:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.40:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://192.168.122.40:2380,etcd-02=https://192.168.122.41:2380,etcd-03=https://192.168.122.42:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

cat > /opt/etcd/cfg/etcd.conf << EOF
#[Member]
ETCD_NAME="etcd-02"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.122.41:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.122.41:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.41:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.41:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://192.168.122.40:2380,etcd-02=https://192.168.122.41:2380,etcd-03=https://192.168.122.42:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF


cat > /opt/etcd/cfg/etcd.conf << EOF
#[Member]
ETCD_NAME="etcd-03"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.122.42:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.122.42:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.122.42:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.122.42:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://192.168.122.40:2380,etcd-02=https://192.168.122.41:2380,etcd-03=https://192.168.122.42:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF


•ETCD_NAME：节点名称，集群中唯一
•ETCDDATADIR：数据目录
•ETCDLISTENPEER_URLS：集群通信监听地址
•ETCDLISTENCLIENT_URLS：客户端访问监听地址
•ETCDINITIALADVERTISEPEERURLS：集群通告地址
•ETCDADVERTISECLIENT_URLS：客户端通告地址
•ETCDINITIALCLUSTER：集群节点地址
•ETCDINITIALCLUSTER_TOKEN：集群Token
•ETCDINITIALCLUSTER_STATE：加入集群的当前状态，new是新集群，existing表示加入已有集群
###systemd管理etcd ###将点1所有生成的文件拷贝到节点2和节点3
cat > /usr/lib/systemd/system/etcd.service << EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=/opt/etcd/cfg/etcd.conf
ExecStart=/usr/local/bin/etcd \
--cert-file=/opt/etcd/ssl/etcd-server.pem \
--key-file=/opt/etcd/ssl/etcd-server-key.pem \
--peer-cert-file=/opt/etcd/ssl/etcd-server.pem \
--peer-key-file=/opt/etcd/ssl/etcd-server-key.pem \
--trusted-ca-file=/opt/etcd/ssl/ca.pem \
--peer-trusted-ca-file=/opt/etcd/ssl/ca.pem \
--logger=zap
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

###启动并设置开机启动
systemctl daemon-reload
systemctl start etcd
systemctl enable etcd


然后在节点2和节点3分别修改etcd.conf配置文件中的节点名称和当前服务器IP：
vi /opt/etcd/cfg/etcd.conf
#[Member]
ETCD_NAME="etcd-1"   # 修改此处，节点2改为etcd-2，节点3改为etcd-3
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.31.71:2380"   # 修改此处为当前服务器IP
ETCD_LISTEN_CLIENT_URLS="https://192.168.31.71:2379" # 修改此处为当前服务器IP

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.31.71:2380" # 修改此处为当前服务器IP
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.31.71:2379" # 修改此处为当前服务器IP
ETCD_INITIAL_CLUSTER="etcd-1=https://192.168.31.71:2380,etcd-2=https://192.168.31.72:2380,etcd-3=https://192.168.31.73:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
最后启动etcd并设置开机启动，同上。
###查看集群状态
ETCDCTL_API=3 /usr/local/bin/etcdctl --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/etcd-server.pem --key=/opt/etcd/ssl/etcd-server-key.pem --endpoints="https://192.168.122.40:2379,https://192.168.122.41:2379,https://192.168.122.42:2379" endpoint health --write-out=table
+-----------------------------+--------+------------+-------+
|          ENDPOINT           | HEALTH |    TOOK    | ERROR |
+-----------------------------+--------+------------+-------+
| https://192.168.122.40:2379 |   true | 7.115954ms |       |
| https://192.168.122.41:2379 |   true | 6.846776ms |       |
| https://192.168.122.42:2379 |   true | 7.294712ms |       |
+-----------------------------+--------+------------+-------+

如果输出上面信息，就说明集群部署成功。
如果有问题第一步先看日志：/var/log/message 或 journalctl -u etcd



##添加阿里云YUM软件源
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
###安装kubeadm，kubelet和kubectl
由于版本更新频繁，这里指定版本号部署：
yum install -y kubelet-1.20.0 kubeadm-1.20.0 kubectl-1.20.0


##部署Kubernetes Master
##初始化Master1
生成初始化配置文件：
cat > kubeadm-config.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: 9037x2.tcaqnpaqkra9vsbw
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.122.40
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: k8s-m01
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  certSANs:  # 包含所有Master/LB/VIP IP，一个都不能少！为了方便后期扩容可以多写几个预留的IP。
  - k8s-m01
  - k8s-m02
  - k8s-m03
  - etcd-01
  - etcd-02
  - etcd-03
  - 192.168.122.40
  - 192.168.122.41
  - 192.168.122.42
  - 192.168.122.43
  - 192.168.122.44
  - 192.168.122.45
  - 192.168.122.46
  - 192.168.122.47
  - 127.0.0.1
  extraArgs:
    authorization-mode: Node,RBAC
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager:
  extraArgs:
        horizontal-pod-autoscaler-use-rest-clients: "true"
        horizontal-pod-autoscaler-sync-period: "10s"
        node-monitor-grace-period: "10s"
controlPlaneEndpoint: 192.168.122.47:6443 # 负载均衡虚拟IP（VIP）和端口
dns:
  type: CoreDNS
etcd:
  external:  # 使用外部etcd
    endpoints:
    - https://192.168.122.40:2379 # etcd集群3个节点
    - https://192.168.122.41:2379
    - https://192.168.122.42:2379
    caFile: /opt/etcd/ssl/ca.pem # 连接etcd所需证书
    certFile: /opt/etcd/ssl/etcd-server.pem
    keyFile: /opt/etcd/ssl/etcd-server-key.pem
imageRepository: registry.aliyuncs.com/google_containers # 由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址
kind: ClusterConfiguration
kubernetesVersion: v1.20.0 # K8s版本，与上面安装的一致
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/16  # Pod网络，与下面部署的CNI网络组件yaml中保持一致
  serviceSubnet: 10.96.0.0/12  # 集群内部虚拟网络，Pod统一访问入口
scheduler: {}
---
# 开启 IPVS 模式
apiVersion: kubeadm.k8s.io/v1beta2
kind: KubeProxyConfiguration
featureGates:
  supportipvsproxymodedm.ymlvim kubeadm.yml: true
  mode: ipvs
EOF
###或者使用配置文件引导：
kubeadm init --config kubeadm-config.yaml
...
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 192.168.122.47:6443 --token 9037x2.tcaqnpaqkra9vsbw \
    --discovery-token-ca-cert-hash sha256:322396870a7f77e1b1ceab36734c3cf599e31f088e1b79c7c6bc13d69f02ea9b \
    --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.122.47:6443 --token 9037x2.tcaqnpaqkra9vsbw \
      --discovery-token-ca-cert-hash sha256:322396870a7f77e1b1ceab36734c3cf599e31f088e1b79c7c6bc13d69f02ea9b

###初始化完成后，会有两个join的命令，带有 --control-plane 是用于加入组建多master集群的，不带的是加入节点的。
###拷贝kubectl使用的连接k8s认证文件到默认路径：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get node
NAME          STATUS     ROLES                  AGE     VERSION
k8s-master1   NotReady   control-plane,master   6m42s   v1.20.0
###初始化Master2
将Master1节点生成的证书拷贝到Master2：
 scp -r /etc/kubernetes/pki/ 192.168.122.41:/etc/kubernetes/
复制加入master join命令在master2执行：
kubeadm join 192.168.122.47:6443 --token 9037x2.tcaqnpaqkra9vsbw \
    --discovery-token-ca-cert-hash sha256:322396870a7f77e1b1ceab36734c3cf599e31f088e1b79c7c6bc13d69f02ea9b \
    --control-plane
拷贝kubectl使用的连接k8s认证文件到默认路径：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


###初始化Master3
将Master1节点生成的证书拷贝到Master2：
 scp -r /etc/kubernetes/pki/ 192.168.122.42:/etc/kubernetes/
复制加入master join命令在master2执行：
kubeadm join 192.168.122.47:6443 --token 9037x2.tcaqnpaqkra9vsbw \
    --discovery-token-ca-cert-hash sha256:322396870a7f77e1b1ceab36734c3cf599e31f088e1b79c7c6bc13d69f02ea9b \
    --control-plane
拷贝kubectl使用的连接k8s认证文件到默认路径：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


kubectl  get nodes
NAME      STATUS     ROLES                  AGE     VERSION
k8s-m01   NotReady   control-plane,master   4m32s   v1.20.0
k8s-m02   NotReady   control-plane,master   7m33s   v1.20.0
k8s-m03   NotReady   control-plane,master   12s     v1.20.0
注：由于网络插件还没有部署，还没有准备就绪 NotReady
###访问负载均衡器测试
找K8s集群中任意一个节点，使用curl查看K8s版本测试，使用VIP访问：
curl -k https://192.168.122.47:6443/version
{
  "major": "1",
  "minor": "20",
  "gitVersion": "v1.20.0",
  "gitCommit": "af46c47ce925f4c4ad5cc8d1fca46c7b77d13b38",
  "gitTreeState": "clean",
  "buildDate": "2020-12-08T17:51:19Z",
  "goVersion": "go1.15.5",
  "compiler": "gc",
  "platform": "linux/amd64"
}

###可以正确获取到K8s版本信息，说明负载均衡器搭建正常。该请求数据流程：curl -> vip(haproxy) -> apiserver
通过查看Nginx日志也可以看到转发apiserver IP：
tail /var/log/nginx/k8s-access.log -f
192.168.31.71 192.168.31.71:6443 - [02/Apr/2021:19:17:57 +0800] 200 423
192.168.31.71 192.168.31.72:6443 - [02/Apr/2021:19:18:50 +0800] 200 423
##node节点进行加入
在192.168.122.43（Node）执行。
向集群添加新节点，执行在kubeadm init输出的kubeadm join命令：
kubeadm join 192.168.122.47:6443 --token 9037x2.tcaqnpaqkra9vsbw \
      --discovery-token-ca-cert-hash sha256:322396870a7f77e1b1ceab36734c3cf599e31f088e1b79c7c6bc13d69f02ea9b

后续其他节点也是这样加入。
注：默认token有效期为24小时，当过期之后，该token就不可用了。这时就需要重新创建token，可以直接使用命令快捷生成：kubeadm token create --print-join-command
###部署网络组件
wget https://docs.projectcalico.org/manifests/calico.yaml
Calico是一个纯三层的数据中心网络方案，是目前Kubernetes主流的网络方案。
部署Calico：
kubectl apply -f calico.yaml
##在所有节点执行：
docker pull registry.aliyuncs.com/google_containers/coredns:1.8.0
docker tag registry.aliyuncs.com/google_containers/coredns:1.8.0 registry.aliyuncs.com/google_containers/coredns/coredns:v1.8.0

kubectl get pods -n kube-system
等Calico Pod都Running，节点也会准备就绪：
kubectl  get nodes
NAME      STATUS   ROLES                  AGE     VERSION
k8s-m01   Ready    control-plane,master   58m     v1.20.0
k8s-m02   Ready    control-plane,master   61m     v1.20.0
k8s-m03   Ready    control-plane,master   54m     v1.20.0
k8s-n01   Ready    <none>                 3m47s   v1.20.0
k8s-n02   Ready    <none>                 3m39s   v1.20.0

##kubeadm方式修改ipvs模式
kubectl edit configmap kube-proxy -n kube-system
  mode: "ipvs"

##部署Dashboard管理k8s集群
Dashboard是官方提供的一个UI，可用于基本管理K8s资源。
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml
课件中文件名是：kubernetes-dashboard.yaml
默认Dashboard只能集群内部访问，修改Service为NodePort类型，暴露到外部：
vi recommended.yaml
...
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
...

kubectl apply -f recommended.yaml
kubectl get pods -n kubernetes-dashboard
访问地址：https://NodeIP:30001
创建service account并绑定默认cluster-admin管理员集群角色：
# 创建用户
kubectl create serviceaccount dashboard-admin -n kube-system
# 用户授权
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 获取用户Token
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
使用输出的token登录Dashboard。

