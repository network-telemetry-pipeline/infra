# Network Telemetry Pipeline — Infra

Infrastructure-as-code for a self-managed Kubernetes platform on GCP.

Part of the `network-telemetry-pipeline` project. See also:
- `network-telemetry-pipeline/pipeline` — Spark Structured Streaming job
- `network-telemetry-pipeline/producer` — Python Kafka producer

---

## Architecture

```
+---------------------------+
|      Platform Layer       |  NGINX Ingress, Cert-Manager, ArgoCD, Prometheus + Grafana
+---------------------------+
|       Data Layer          |  Kafka (Strimzi), MinIO (S3)
+---------------------------+
|      Cluster Layer        |  Kubernetes (kubeadm), Cilium CNI, StorageClass
+---------------------------+
|   Infrastructure Layer    |  GCP VMs, VPC, firewall rules
+---------------------------+
```

```
Terraform → Ansible → Kubernetes → Platform Services
```

---

## Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform (GCP VMs, VPC, firewall) |
| Cluster bootstrap | Ansible + kubeadm |
| CNI | Cilium |
| GitOps | ArgoCD |
| Ingress / TLS | NGINX Ingress + Cert-Manager |
| Observability | Prometheus + Grafana |
| Object storage | MinIO AIStor (S3-compatible) |
| Streaming | Kafka via Strimzi (KRaft, no ZooKeeper) |

---

## Cluster

- 3 GCP VMs — 1 control-plane + 2 workers (`e2-medium`, Ubuntu 22.04, 40 GB)
  - `k8s-cp-01` — control-plane (`10.50.0.21`)
  - `k8s-worker-01` — worker, static external IP (`10.50.0.22`)
  - `k8s-worker-02` — worker (`10.50.0.23`)
- Subnet: `10.50.0.0/24`

### Firewall rules

| Rule | Ports | Source |
|---|---|---|
| SSH | 22 | `admin_cidr` only |
| Internal cluster traffic | all TCP/UDP/ICMP | subnet |
| NodePort range (internal) | 30000–32767 | subnet |
| HTTP/HTTPS | 80, 443 | `0.0.0.0/0` |
| Kafka NodePort | 30994, 30995 | `admin_cidr` |
| MinIO NodePort | 31000, 31001 | `admin_cidr` |

---

## Quick Start

### Prerequisites

- `terraform`, `ansible-playbook`, `gcloud` installed and authenticated
- GCP project configured in `terraform/terraform.tfvars`:

```hcl
project_id          = "your-gcp-project"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
admin_cidr          = "your.ip.address/32"
```

### Step 1 — Create a static external IP

Must exist before running Terraform:

```bash
gcloud compute addresses create net-tel-w01-ip \
  --region=europe-west1
```

Point your DNS A record to this IP (required for TLS cert issuance).

### Step 2 — Deploy everything

```bash
./deploy.sh
```

Or run phases individually:

```bash
./deploy.sh terraform   # provision GCP infrastructure only
./deploy.sh ansible     # bootstrap cluster and deploy platform only
```

### Tear down

```bash
cd terraform && terraform destroy
```

---

## Ansible Plays

| Play | Hosts | What it does |
|---|---|---|
| Base setup | all | OS hardening, containerd, Kubernetes packages |
| Control plane init | control-plane | `kubeadm init`, kubeconfig |
| Worker join | workers | `kubeadm join` |
| Cilium | control-plane | CNI installation |
| NGINX Ingress | control-plane | Ingress controller |
| Cert-Manager | control-plane | Let's Encrypt TLS automation |
| ArgoCD | control-plane | GitOps controller |
| Prometheus + Grafana | control-plane | Observability stack |
| Ingress routes | control-plane | Expose ArgoCD and Grafana via Ingress |
| Local Path storage | control-plane | Default StorageClass |
| Kafka | control-plane | Strimzi operator + KRaft cluster |
| MinIO | control-plane | AIStor object store |

Key variables in `ansible/group_vars/all.yml`:

| Variable | Value |
|---|---|
| `kubernetes_minor` | `v1.35` |
| `cilium_version` | `1.19.0` |
| `pod_cidr` | `10.244.0.0/16` |
| `service_cidr` | `10.96.0.0/12` |
| `platform_domain` | `ccmllab.mooo.com` |

---

## Repository Structure

```
.
├── deploy.sh               # One-shot deployment script
├── terraform/              # GCP provisioning
└── ansible/                # Cluster bootstrap + platform install
    ├── site.yml
    ├── group_vars/all.yml
    └── roles/              # containerd, kubernetes, cilium, kafka, minio, ...
```

---

## What This Demonstrates

- Infrastructure as Code (Terraform + Ansible)
- Self-managed Kubernetes cluster bootstrap
- Stateful workloads on Kubernetes (Kafka, MinIO)
- Observability with Prometheus & Grafana
- TLS automation with Cert-Manager + Let's Encrypt
