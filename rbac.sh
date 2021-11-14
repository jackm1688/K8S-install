openssl genrsa -out marray.key 2048
openssl req -new -key marray.key  -out marray.csr -subj "/CN=marray/O=anchnet-k8s/"
openssl x509 -req -in marray.csr -CA /etc/kubernetes/pki/ca.crt  -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out marray.crt --days 3650 


kubectl  config set-cluster anchet-k8s --embed-certs=true --certificate-authority=/etc/kubernetes/pki/ca.crt --server=https://192.168.122.47:6443
kubectl  config set-credentials marray --embed-certs=true --client-certificate=marray.crt --client-key=marray.key 
kubectl  config set-context marray@anchet-k8s --cluster=anchnet-k8s --user=marray
