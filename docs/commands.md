# Commands

## Cluster

```bash
kubectl get nodes -o wide
kubectl top nodes
```

## Workloads

```bash
kubectl get pods -A -o wide
kubectl get deploy -A
kubectl get statefulset -A
kubectl get svc -A
kubectl get ingress -A
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl rollout restart deployment <name> -n <ns>
kubectl rollout restart statefulset <name> -n <ns>
kubectl delete pod <pod> -n <ns>
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

## Storage

```bash
kubectl get pvc -A
kubectl get pv
kubectl get sc
kubectl get volumes -n longhorn-system
kubectl get volumeattachment
```

## Scaling

```bash
kubectl get hpa -A
kubectl get rs -A
```

## Helm

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm search repo <name>
helm show values <chart> > values.yaml
helm install <name> <chart> -n <ns> --create-namespace -f values.yaml
helm upgrade <name> <chart> -n <ns> -f values.yaml
helm uninstall <name> -n <ns>
```

## Vault

```bash
kubectl exec -n vault vault-0 -- vault operator init
kubectl exec -n vault vault-0 -- vault operator unseal
kubectl exec -it -n vault vault-0 -- vault login
vault status
vault secrets list
vault auth list
vault read -field=public_key ssh/config/ca
```

## LDAP

```bash
kubectl exec -it <openldap-pod> -n ldap -- ldapsearch -x -H ldap://localhost -b dc=dc1,dc=local
```
