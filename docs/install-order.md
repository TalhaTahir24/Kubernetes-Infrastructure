# Install Order

Do not change this order. Each layer is a dependency for the next.

```text
 1. K3s                cluster up, all nodes Ready
 2. Traefik            already bundled with K3s
 3. Longhorn           storage before any stateful workload
 4. Vault              secrets (init/unseal/login before configuring)
 5. OpenLDAP           identity directory
 6. phpLDAPadmin       LDAP management UI
 7. Authelia           SSO in front of internal services
 8. FastAPI services   application layer
 9. Harbor             (next)
10. MinIO              (next)
11. Monitoring         (next)
12. Logging            (next)
13. GitLab             (next)
```

## Rebuild checklist

```bash
# 1. cluster
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
kubectl get nodes -w

# 2. namespaces + storage
kubectl apply -f k3s/namespaces.yaml
kubectl apply -f longhorn/
kubectl get pods -n longhorn-system -w

# 3. secrets
helm install vault hashicorp/vault -n vault --create-namespace -f vault/values.yaml
kubectl exec -n vault vault-0 -- vault operator init
kubectl exec -n vault vault-0 -- vault operator unseal   # x3

# 4. identity
kubectl apply -f openldap/
kubectl apply -f phpldapadmin/

# 5. SSO
kubectl apply -f authelia/

# 6. apps
kubectl apply -f workloads/
```
