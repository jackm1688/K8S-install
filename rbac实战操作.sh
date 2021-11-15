""""
这里rbac工作原理，可以去官网看介绍哈。
使用组进行集中管理一批用户,无需单独去为每个用户创建权限，只需要将用户加入到指定组即即可继承组中的权限。
一个用户可以加入不同的组，继承不同组中的的权限。
""""
##创建一个开发组:dev
openssl genrsa -out dev.key 2048
openssl req -new -key dev.key -out dev.csr -subj "/O=dev/"
openssl x509 -req -in dev.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key  -CAcreateserial -out dev.crt -days 3650

kubectl  config set-cluster dev-k8s --embed-certs=true --certificate-authority=/etc/kubernetes/pki/ca.crt --server=https://192.168.122.47:6443



##授权开发组dev只能查询kube-system名称空间下的Pod对象
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: kube-system
  name: dev-role
rules:
  - verbs:
      - get
      - list
    apiGroups:
      - ""
    resources:
      - pods
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-rolebinding
  namespace: kube-system
subjects:
  - kind: Group
    name: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ev-role

##创建一个运维组:ops
openssl genrsa -out ops.key 2048
openssl req -new -key ops.key -out ops.csr -subj "/O=ops/"
openssl x509 -req -in ops.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key  -CAcreateserial -out ops.crt -days 3650

###创建权限绑定，可以查询deployments和statefulset资源对象
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: kube-system
  name: ops-role
rules:
  - verbs:
      - get
      - list
    apiGroups:
      - ""
      - apps
    resources:
      - deployments
      - statefulsets
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ops-rolebinding
  namespace: kube-system
subjects:
  - kind: Group
    name: ops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ops-role





##创建用户user1
openssl genrsa -out user1.key 2048
openssl req -new -key user1.key -out user1.csr -subj "/CN=user1/O=dev/"
openssl x509 -req -in user1.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key  -CAcreateserial -out user1.crt -days 3650

kubectl  config set-credentials user1 --embed-certs=true --client-certificate=user1.crt --client-key=user1.key
kubectl config set-context user1@dev-k8s --cluster=dev-k8s --user=user1
kubectl config use-context user1@dev-k8s

###测试查询结果
kubectl  get pod  -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-659bd7879c-5jgpq   1/1     Running   13         18d
calico-node-2qmq7                          1/1     Running   11         18d
calico-node-6dlsb                          1/1     Running   9          18d
calico-node-fghzt                          1/1     Running   13         18d
calico-node-fmgm7                          1/1     Running   11         18d
calico-node-wlf45                          1/1     Running   12         18d
coredns-7f89b7bc75-pm4hl                   1/1     Running   9          18d

###测试查询deploy资源对象，返回需结果提示需要认证
kubectl  get svc -n kube-system
Error from server (Forbidden): services is forbidden: User "user1" cannot list resource "services" in API group "" in the namespace "kube-system"


##创建用户user2
openssl genrsa -out user2.key 2048
openssl req -new -key user2.key -out user2.csr -subj "/CN=user2/O=dev/"
openssl x509 -req -in user2.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key  -CAcreateserial -out user2.crt -days 3650

kubectl  config set-credentials user2 --embed-certs=true --client-certificate=user2.crt --client-key=user2.key
kubectl config  set-context  user2@dev-k8s --cluster=dev-k8s --user=user2
kubectl config use-context user2@dev-k8s

###测试查询结果，查询default名称空间下的pod提示权限
kubectl  get pod
Error from server (Forbidden): pods is forbidden: User "user2" cannot list resource "pods" in API group "" in the namespace "default"

###测试查询kube-system名称空间下的Pod资源对象
kubectl  get pod  -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-659bd7879c-5jgpq   1/1     Running   13         18d
calico-node-2qmq7                          1/1     Running   11         18d
calico-node-6dlsb                          1/1     Running   9          18d
calico-node-fghzt                          1/1     Running   13         18d
calico-node-fmgm7                          1/1     Running   11         18d
calico-node-wlf45                          1/1     Running   12         18d


##创建用户user3
openssl genrsa -out user3.key 2048
openssl req -new -key user3.key -out user3.csr -subj "/CN=user3/O=dev/O=ops/"
openssl x509 -req -in user3.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key  -CAcreateserial -out user3.crt -days 3650

kubectl  config set-credentials user3 --embed-certs=true --client-certificate=user3.crt --client-key=user3.key
kubectl config  set-context  user3@dev-k8s --cluster=dev-k8s --user=user3
kubectl config use-context user3@dev-k8s


###测试，查询deployments资源对象
kubectl  get deploy -n kube-system
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
calico-kube-controllers   1/1     1            1           18d
coredns                   2/2     2            2           18d
metrics-server            1/1     1            1           18d
nginx-app                 1/1     1            1           81s

##测试，查询pod资源对象
 kubectl  get pod  -n kube-system
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-659bd7879c-5jgpq   1/1     Running   13         18d
calico-node-2qmq7                          1/1     Running   11         18d
calico-node-6dlsb                          1/1     Running   9          18d
calico-node-fghzt                          1/1     Running   13         18d
calico-node-fmgm7                          1/1     Running   11         18d
calico-node-wlf45                          1/1     Running   12         18d
coredns-7f89b7bc75-pm4hl                   1/1     Running   9          18d

