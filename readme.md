# Kubernetes-Infrastructure

Kubernetes manifests for core cluster services: internal DNS (BIND9), web serving with ingress (NGINX + Traefik), and secrets management (Vault). Deployed on a homelab cluster and managed through GitOps with ArgoCD.

## Layout

```
.
├── bind9/     BIND9 DNS: ConfigMap-backed zone, Deployment with PVC, ArgoCD Application
├── nginx/     NGINX Deployment (3 replicas), Service, Traefik IngressRoute, Kustomize
└── vault/     Vault Deployment, Ingress
```

## Components

| Component | What it does |
|-----------|--------------|
| BIND9 | Internal DNS for the cluster and workloads; zone config lives in a ConfigMap so it deploys without rebuilds |
| NGINX | Serves web workloads; exposed through a Traefik IngressRoute on websecure |
| Vault | Central secrets management, reached through a TLS ingress |

## Deploying

```bash
git clone https://github.com/TalhaTahir24/Kubernetes-Infrastructure.git
cd Kubernetes-Infrastructure

kubectl apply -f bind9/
kubectl apply -f nginx/
kubectl apply -f vault/
```

Namespaces and ingress hostnames are placeholders (`*.homelab.lab`) — set them to your own domain before applying.

## GitOps

`bind9/argocd-app.yaml` registers the DNS component as an ArgoCD Application (`repoURL` points at this repository) so changes converge automatically instead of being applied by hand.

## Requirements

- Kubernetes cluster
- `kubectl` configured
- Optional: ArgoCD for the GitOps path

## Notes

- BIND9 needs a persistent volume for its zone data (see PVC in `bind9/deployment.yaml`).
- Vault requires proper secrets and TLS config before production use.
- The DNS zone and ingress hosts use a placeholder internal domain; substitute your own.
