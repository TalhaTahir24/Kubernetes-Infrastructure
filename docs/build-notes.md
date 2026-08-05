# Build Notes

Personal deployment notes. Final working steps only, plus the mistakes that cost time.

## Environment

- DC: DC1
- Nodes: mi-k3s-01 (control plane), mi-k3s-02, mi-k3s-03 (workers)
- OS: Ubuntu Server
- Ingress: Traefik (built into K3s)
- Storage: Longhorn
- Secrets: Vault
- Identity: OpenLDAP
- SSO: Authelia

Rules:

- Everything HTTP is exposed through Traefik ingress; no NodePort/LoadBalancer unless required.
- Every stateful workload uses a Longhorn PVC.
- Vault stores secrets, OpenLDAP holds identities, Authelia guards internal apps.
- No MetalLB. Pangolin is testing-only and not used for internal apps.

## K3s

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

Verify every node is `Ready` before installing anything. Never continue with a `NotReady` node.

## Traefik

Already installed with K3s. Expose services by creating an ingress (see `traefik/ingress-template.yaml`).

```bash
kubectl get ingress -A
```

Problem: service unreachable. Reason: no ingress created. Fix: create a Traefik ingress.

## Longhorn

```bash
apt update
apt install open-iscsi -y
systemctl enable --now iscsid

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
```

```bash
kubectl get pods -n longhorn-system
kubectl get volumes -n longhorn-system
kubectl get sc
```

UI is exposed at `longhorn.dc1.local` through a Traefik ingress.

Problems faced:

1. GUI inaccessible — only ClusterIP service. Fixed by creating a Traefik ingress.
2. PVC stuck, pod `ContainerCreating` — `ReplicaSchedulingFailure`. Fixed by reducing replicas to 2 for the lab (Longhorn default is 3).
3. Volume detached — replica not schedulable. Check the Longhorn UI and fix replica scheduling before touching the workload.

Never reinstall Longhorn or delete the PVC immediately. Check the volume status first.

## Vault

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault -n vault --create-namespace -f vault/values.yaml
```

```bash
kubectl exec -n vault vault-0 -- vault operator init    # save root token + unseal keys
kubectl exec -n vault vault-0 -- vault operator unseal # x3
kubectl exec -it -n vault vault-0 -- vault login       # root token
vault auth enable kubernetes
```

Problems faced:

1. 403 permission denied — not logged in. Login with the root token.
2. Vault sealed — forgot to unseal. Unseal three times.
3. Could not enable Kubernetes auth — Vault not initialized. Init first, then unseal, then login, then configure auth.

Never enable auth before login. Never lose the root token or unseal keys.

## OpenLDAP

OpenLDAP stack (osixia image), not the old Bitnami chart. Storage on a Longhorn PVC, namespace `ldap`, base DN `dc=dc1,dc=local`.

```bash
kubectl apply -f openldap/
kubectl get pods -n ldap -w
kubectl get svc -n ldap
```

Problems faced:

1. Old Helm chart failed — `extensions/v1beta1` ingress. Use a maintained chart/image.
2. `ContainerCreating` forever — Longhorn volume faulted, replica scheduling failed. LDAP was never the issue; fix Longhorn first.
3. Edited a huge values file — YAML syntax error. Keep values minimal; only change what is required.

Test with `ldapsearch` before wiring Authelia to it.

## phpLDAPadmin

Web UI for OpenLDAP, namespace `ldap`, exposed at `phpldapadmin.dc1.local`. LDAP server is always referenced by Kubernetes service DNS: `openldap.ldap.svc.cluster.local`.

Login DN: full admin DN for the base in use. Never use `localhost` or a node IP for the LDAP host.

## Authelia

SSO portal at `authelia.dc1.local`. Backend is OpenLDAP, storage is SQLite for the lab.

Problems faced:

1. Authentication failed — wrong base DN. Use `dc=dc1,dc=local`.
2. Could not connect to LDAP — wrong hostname. Use `openldap.ldap.svc.cluster.local`.
3. User not found — wrong users DN. Verify the OU and base DN.

Never configure Authelia before LDAP works.

## Lessons

1. Check storage before the application. 80% of stateful failures were Longhorn issues.
2. Traefik ingress fixed almost every UI access problem.
3. Vault: init, unseal, login, then configure.
4. Install Helm before using Helm charts.
5. Use maintained charts only, and keep values files minimal.
6. Validate dependencies first; build one service completely before the next.

## Status

Done: K3s, Traefik, Longhorn, Vault (KV + PKI + SSH CA), OpenLDAP, phpLDAPadmin, Authelia.

Next: phpLDAPadmin final production config, Harbor, MinIO, monitoring, logging, GitLab.
