# K3s Setup (DC1)

## Nodes

| Node        | Role          |
|-------------|---------------|
| mi-k3s-01   | Control plane |
| mi-k3s-02   | Worker        |
| mi-k3s-03   | Worker        |

Each node runs Ubuntu Server with ~25 GB free disk. K3s ships with Traefik as the default ingress controller, so there is no separate ingress install.

## Install

Control plane:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

Workers:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://mi-k3s-01:6443 K3S_TOKEN=<node-token> sh -
```

The node token lives on the control plane at `/var/lib/rancher/k3s/server/node-token`.

## Verify

```bash
kubectl get nodes          # all three must be Ready
kubectl get pods -A        # all system pods Running
kubectl get svc -A
kubectl get ingressclass
```

Never install a workload until every node is `Ready`. A `NotReady` worker means storage and stateful pods will fail to schedule.

## Namespaces

```bash
kubectl apply -f k3s/namespaces.yaml
```

## Helpful one-liners

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl top nodes          # watch the 25 GB/node headroom
```
