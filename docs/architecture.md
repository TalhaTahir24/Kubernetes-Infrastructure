# DC1 Architecture

A production-like enterprise Kubernetes platform that simulates a real company environment while staying lightweight enough for a homelab. The cluster hosts infrastructure services, identity, secrets, monitoring, and internal applications.

## Cluster

| Component | Value |
|-----------|-------|
| Kubernetes | K3s |
| Nodes | 3 (1 control plane, 2 workers) |
| OS | Ubuntu Server |
| Container runtime | containerd |
| Networking | Flannel (K3s default) |
| Ingress | Traefik |
| Storage | Longhorn |

### Node layout

| Node | Role |
|------|------|
| mi-k3s-01 | Control plane (etcd, scheduler, API server, controller manager) |
| mi-k3s-02 | Worker |
| mi-k3s-03 | Worker |

All nodes participate in scheduling. Each node has ~25 GB of free storage, which drives the Longhorn replica count and volume sizing.

## Services

| Category | Service | Purpose |
|----------|---------|---------|
| Ingress | Traefik | Reverse proxy, ingress controller, TLS termination |
| Storage | Longhorn | Distributed persistent storage (PVC provisioning, replication, CSI) |
| Identity | OpenLDAP | Central user/group/OU directory |
| Identity | phpLDAPadmin | LDAP management web UI |
| Authentication | Authelia | SSO gateway in front of internal services |
| Secrets | Vault | Secrets, API keys, database credentials, certificates |
| Applications | FastAPI services | Internal APIs backed by Vault + a database |

### Authentication flow

```
User
  ↓
Traefik
  ↓
Authelia
  ↓
OpenLDAP
```

### Secrets flow

Workloads authenticate to Vault through Kubernetes service accounts, not static credentials. The API tier reads connection details and credentials from Vault rather than shipping them in manifests.

```
FastAPI
  ↓ (service account token)
Vault
  ↓
Database / secrets
```

## Scaling

### Node scaling

- Current: 1 control plane + 2 workers.
- Target: 3 control planes + 5+ workers for HA control plane and more capacity.

### Application scaling

- `HorizontalPodAutoscaler` on CPU utilisation (see `workloads/hpa.yaml`).
- Rolling updates, health probes, self-healing pods.

### Storage scaling

- Longhorn volumes expand on demand and replicas can be increased or migrated live.
- Replicas were reduced from 3 to 2 because of the per-node storage ceiling.

## Future / planned

- Data services: PostgreSQL HA, MariaDB, Redis, RabbitMQ, MinIO
- Observability: Prometheus, Grafana, Loki, Tempo, Alertmanager
- GitOps: ArgoCD / Flux
- CI/CD: GitHub Actions runners, Jenkins
- Security: Falco, Trivy, Kyverno, External Secrets Operator, cert-manager
- Networking: MetalLB, ExternalDNS
- Service mesh: Istio / Linkerd

## Maturity

The platform covers ingress, persistent storage, central identity, secrets management, and application hosting. The next stage is observability, GitOps and CI/CD, highly available data services, and policy/runtime security hardening.
