

default/test-claim" class "managed-nfs-storage": unexpected error getting claim reference: selfLink was empty, can't make reference

https://stackoverflow.com/questions/65376314/kubernetes-nfs-provider-selflink-was-empty


pec:
  containers:
  - command:
    - kube-apiserver
    - --feature-gates=RemoveSelfLink=false
