# Kubernetes-Infrastructure

Manifests for **DC1**, a production-like homelab Kubernetes platform. Three-node K3s cluster running ingress, distributed storage, centralized identity, secrets management, and internal applications — the same patterns used for enterprise internal platforms.

## Environment

| Component | Value |
|-----------|-------|
| Cluster | K3s (1 control plane, 2 workers) |
| Nodes | mi-k3s-01 / mi-k3s-02 / mi-k3s-03 |
| OS | Ubuntu Server |
| Ingress | Traefik (bundled with K3s) |
| Storage | Longhorn, 2 replicas (~25 GB free per node) |
| Secrets | Vault (KV, PKI, SSH CA, Kubernetes auth) |
| Identity | OpenLDAP + phpLDAPadmin |
| SSO | Authelia |

Operating rules:

- Every HTTP workload goes through a Traefik ingress; no NodePort or LoadBalancer.
- Every stateful workload uses a Longhorn PVC; no hostPath or local-path.
- Workloads authenticate to Vault via Kubernetes service accounts, not static credentials.

See `docs/architecture.md` for the full picture.

## Layout

| Directory | Purpose |
|-----------|---------|
| `k3s/` | Cluster setup, namespaces, verification |
| `traefik/` | Reusable ingress template and middlewares |
| `longhorn/` | Storage class and UI ingress |
| `vault/` | Helm values, ingress, policies, PKI, SSH CA, Kubernetes auth |
| `openldap/` | LDAP directory on Longhorn storage |
| `phpldapadmin/` | LDAP management UI |
| `authelia/` | SSO portal |
| `workloads/` | Stateless, stateful, init-container, FastAPI and HPA examples |
| `ssh-ca/` | Client script + docs for Vault-signed SSH certificates |
| `docs/` | Architecture, build notes, install order, commands |

## Deploying

Order matters — see `docs/install-order.md`. The short version:

```bash
kubectl apply -f k3s/namespaces.yaml
kubectl apply -f longhorn/                       # storage first

helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace -f vault/values.yaml
kubectl apply -f vault/ingress.yaml

kubectl apply -f openldap/ phpldapadmin/
kubectl apply -f authelia/
kubectl apply -f workloads/
```

Placeholder secrets are marked `changeme` in the manifests — generate your own before applying. DNS names use the internal domain `dc1.local`.

## Vault SSH CA

User workstations don't keep long-lived keys on servers. Vault signs short-lived SSH certificates instead:

- Server side: `vault/ssh-ca/setup.sh` enables the `ssh` engine and creates the `ubuntu-ca` role.
- Client side: `ssh-ca/renew-ssh-cert.sh` uploads the key, signs it, installs `~/.ssh/id_ed25519-cert.pub`, and verifies with `ssh-keygen -L`.
- Trust: servers point `TrustedUserCAKeys` at the CA public key.

See `docs/ssh-certificate-workflow.md`.

## Docs

- `docs/architecture.md` — cluster, services, scaling, future direction
- `docs/build-notes.md` — what was built and what went wrong along the way
- `docs/install-order.md` — rebuild checklist
- `docs/commands.md` — commands actually used
- `docs/ssh-certificate-workflow.md` — Vault SSH CA end to end
