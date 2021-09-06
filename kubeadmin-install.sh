52:54:00:d5:a0:6c adm-k8s-master
52:54:00:25:9a:28 adm-k8s-node1
52:54:00:11:57:d9 adm-k8s-node2


for i in adm-k8s-master adm-k8s-node1 adm-k8s-node2 k8s-master1 k8s-master2 k8s-master3 k8s-node1 k8s-node2 k8s-node3 k8s-nginx-master k8s-nginx-slave k8s-gitserver k8s-harbor; do echo $i && virsh start $i; done;
for i in adm-k8s-master adm-k8s-node1 adm-k8s-node2 k8s-master1 k8s-master2 k8s-master3 k8s-node1 k8s-node2 k8s-node3 k8s-nginx-master k8s-nginx-slave k8s-gitserver k8s-harbor; do echo $i && virsh destroy $i; done;

##close swap
# 安装docker-ce,docker-ce-cli,containerd.io
yum install docker-ce docker-ce-cli containerd.io --allowerasing

# 安装完成后启动docker
systemctl start docker
# 启动docker后设置Dokcer以后开机自启动
systemctl enable docker


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
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
lsmod | grep ip_vs
lsmod | grep nf_conntrack_ipv4
yum install -y ipvsadm


##kubeadm功能
ubeadm工具功能：
•kubeadm init：初始化一个Master节点
•kubeadm join：将工作节点加入集群
•kubeadm upgrade：升级K8s版本
•kubeadm token：管理 kubeadm join 使用的令牌
•kubeadm reset：清空 kubeadm init 或者 kubeadm join 对主机所做的任何更改
•kubeadm version：打印 kubeadm 版本
•kubeadm alpha：预览可用的新功能


##寫host文件
192.168.122.110 adm-k8s-master
192.168.122.111 adm-k8s-ndoe1
192.168.122.112 adm-k8s-node2

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


##install kubelet-1.21.0 kubeadm-1.21.0 kubectl-1.21.0
yum -y install   kubelet-1.21.0 kubeadm-1.21.0 kubectl-1.21.0


##部署Kubernetes Master
在192.168.122.110（Master）执行。
kubeadm init \
  --apiserver-advertise-address=192.168.122.110 \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.21.0 \
  --service-cidr=10.96.0.0/12 \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=all

•--apiserver-advertise-address 集群通告地址
•--image-repository 由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址
•--kubernetes-version K8s版本，与上面安装的一致
•--service-cidr 集群内部虚拟网络，Pod统一访问入口
•--pod-network-cidr Pod网络，，与下面部署的CNI网络组件yaml中保持一致
或者使用配置文件引导：
vi kubeadm.conf
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.21.0
imageRepository: registry.aliyuncs.com/google_containers
networking:
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12

##初始化
kubeadm init --config kubeadm.conf --ignore-preflight-errors=all
初始化完成后，最后会输出一个join命令，先记住，下面用。
拷贝kubectl使用的连接k8s认证文件到默认路径：
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

##查看工作節點
kubectl  get nodes
NAME             STATUS     ROLES                  AGE     VERSION
adm-k8s-master   NotReady   control-plane,master   2m52s   v1.21.0


##注：由于网络插件还没有部署，还没有准备就绪 NotReady
参考资料：
https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node

## 加入Kubernetes Node
在192.168.122.111/112（Node）执行。
##向集群添加新节点，执行在kubeadm init输出的kubeadm join命令：
kubeadm join 192.168.122.110:6443 --token nks9ml.g0zld9wg6pdncv4f --discovery-token-ca-cert-hash sha256:63003a08c99dc268963947f39cfd46b374408ed2f2279e3931cd4d2712b9bdb4

默认token有效期为24小时，当过期之后，该token就不可用了。这时就需要重新创建token，可以直接使用命令快捷生成：
kubeadm token create --print-join-command
参考资料：https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/

## 部署容器网络（CNI）
Calico是一个纯三层的数据中心网络方案，是目前Kubernetes主流的网络方案。
下载YAML：
wget https://docs.projectcalico.org/manifests/calico.yaml
下载完后还需要修改里面定义Pod网络（CALICO_IPV4POOL_CIDR），与前面kubeadm init的 --pod-network-cidr指定的一样。
修改完后文件后，部署：
kubectl apply -f calico.yaml
kubectl get pods -n kube-system
等Calico Pod都Running，节点也会准备就绪


##在所有节点执行：
docker pull registry.aliyuncs.com/google_containers/coredns:1.8.0
docker tag registry.aliyuncs.com/google_containers/coredns:1.8.0 registry.aliyuncs.com/google_containers/coredns/coredns:v1.8.0

##测试kubernetes集群
在Kubernetes集群中创建一个pod，验证是否正常运行：
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get pod,svc
访问地址：http://NodeIP:Port
7. 部署 Dashboard
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


##切换容器引擎为Containerd
参考资料：https://kubernetes.io/zh/docs/setup/production-environment/container-runtimes/#containerd
1、配置先决条件
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 设置必需的 sysctl 参数，这些参数在重新启动后仍然存在。
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
2、安装containerd
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install -y containerd.io
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
3、修改配置文件
•pause镜像设置过阿里云镜像仓库地址
•cgroups驱动设置为systemd
•拉取Docker Hub镜像配置加速地址设置为阿里云镜像仓库地址
vi /etc/containerd/config.toml
   [plugins."io.containerd.grpc.v1.cri"]
      sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.2"
         ...
         [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
             SystemdCgroup = true
             ...
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://b9pmyelo.mirror.aliyuncs.com"]

systemctl restart containerd
4、配置kubelet使用containerd
vi /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock --cgroup-driver=systemd

systemctl restart kubelet
5、验证
kubectl get node -o wide

k8s-node1  xxx  containerd://1.4.4
6、管理容器工具
containerd提供了ctr命令行工具管理容器，但功能比较简单，所以一般会用crictl工具检查和调试容器。
项目地址：https://github.com/kubernetes-sigs/cri-tools/
设置crictl连接containerd：
vi /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
下面是docker与crictl命令对照表：
镜像相关功能	Docker	Containerd
显示本地镜像列表	docker images	crictl images
下载镜像	docker pull	crictl pull
上传镜像	docker push	无，例如buildk
删除本地镜像	docker rmi	crictl rmi
查看镜像详情	docker inspect IMAGE-ID	crictl inspecti IMAGE-ID

容器相关功能	Docker	Containerd
显示容器列表	docker ps	crictl ps
创建容器	docker create	crictl create
启动容器	docker start	crictl start
停止容器	docker stop	crictl stop
删除容器	docker rm	crictl rm
查看容器详情	docker inspect	crictl inspect
attach	docker attach	crictl attach
exec	docker exec	crictl exec
logs	docker logs	crictl logs
stats	docker stats	crictl stats

POD 相关功能	Docker	Containerd
显示 POD 列表	无	crictl pods
查看 POD 详情	无	crictl inspectp
运行 POD	无	crictl runp
停止 POD	无	crictl stopp
注：练习完后，建议还切回Docker引擎，就是把kubelet配置参数去掉即可

