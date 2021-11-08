

金丝雀:
kubectl  patch deploy deploy03 -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
#update image
kubectl  set image deployments deply03 deploy03=k8s-harbor.gdsz.com/library/nginx:v1 && kubectl rollout pause deploy deploy03
#resume
kubectl  rollout resume deploy deploy03



#rollout deploy
kubectl  rollout undo deploy deploy03

#view rollot history
kubectl  rollout history deploy deploy03
deployment.apps/deploy03
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=deploy03.yaml --record=true
4         kubectl apply --filename=deploy03.yaml --record=true
5         kubectl apply --filename=deploy03.yaml --record=true
6         kubectl apply --filename=deploy03.yaml --record=true
7         kubectl apply --filename=deploy03.yaml --record=true
9         kubectl apply --filename=deploy03.yaml --record=true
10        kubectl apply --filename=deploy03.yaml --record=true


##deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: test1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress


##test1名称空间下Pod可以互相访问，也可以其访问其命名空间的下的Pod，但其他名单空间下的pod不能访问test1名称空间下的pod
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  namespace: test1
  name: networkpolicy1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
    - from:
        - podSelector: {} #匹配所有名称空间下的Pod

##允许其他名称空间下pod访问test1名称空间下指定的pod
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: test1
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  namespace: test1
  name: allow-all-namesapce
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
    - from:
        - namespaceSelector: {}


##将test1名称空间中标签为app=web的pod隔离，只允许标签为run=client1的pod访问80端口(同一个名称空间下)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: same-namespace-allow
  namespace: test1
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: client1
      ports:
        - protocol: TCP
          port: 80


---
apiVersion: v1
kind: Pod
metadata:
  namespace: test1
  name: client
  labels:
    app: client1
spec:
  containers:
    - name: client1
      image: nginx


##只允许指定名称空间中的应用访问和其他所有命名空间和其他所有命名空间指定标签的Pod访问
#a. 应用策略命名空间在dev,web的pod标签为env=dev
#b. 允许prod命名空间中的Pod访问，及其他命名空间中的Pod标签为app=client1的pod

