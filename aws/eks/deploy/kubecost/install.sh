helm install kubecost cost-analyzer \
 --repo https://kubecost.github.io/cost-analyzer/ \
 --namespace kubecost --create-namespace \
 --set kubecostToken="c2tvbmRsYS5haUBnbWFpbC5jb20=xm343yadf98"

kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090
