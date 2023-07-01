helm install kubecost cost-analyzer \
 --repo https://kubecost.github.io/cost-analyzer/ \
 --namespace kubecost --create-namespace \
 --set kubecostToken="${kubecostToken}"

kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090
