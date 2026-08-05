# Vault Kubernetes Auth

Service accounts authenticate to Vault instead of using static credentials. The role binds a specific service account to a policy.

```bash
#!/bin/bash
set -euo pipefail

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
K8S_HOST="${K8S_HOST:-https://mi-k3s-01:6443}"

kubectl -n vault create serviceaccount vault-auth \
  --dry-run=client -o yaml | kubectl apply -f -

vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host="$K8S_HOST" \
  token_reviewer_jwt="$(kubectl -n vault create token vault-auth)" \
  kubernetes_ca_cert="$(kubectl -n vault get sa vault-auth -o jsonpath='{.secrets[0].name}' | xargs -I{} kubectl -n vault get secret {} -o jsonpath='{.data.ca\.crt}' | base64 -d)"

vault write auth/kubernetes/role/internal-apps \
  bound_service_account_names=app \
  bound_service_account_namespaces=apps \
  policies=ssh-signing \
  ttl=1h
```
