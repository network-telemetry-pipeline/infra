# Network Telemetry Pipeline — Infra

Infrastructure-as-code for a self-managed Kubernetes platform on GCP.

Part of the `network-telemetry-pipeline` project. See also:
- `network-telemetry-pipeline/data-pipeline` — Spark Structured Streaming jobs
- `network-telemetry-pipeline/producer` — Python Kafka producer
- `network-telemetry-pipeline/dashboard-api` — REST API serving pipeline output

---

## Architecture

```
+---------------------------+
|      Platform Layer       |  NGINX Ingress, Cert-Manager, ArgoCD, Prometheus + Grafana
+---------------------------+
|       Data Layer          |  Kafka (Strimzi), MinIO (S3), PostgreSQL, Spark Operator
+---------------------------+
|      Cluster Layer        |  Kubernetes (kubeadm), Cilium CNI, StorageClass
+---------------------------+
|   Infrastructure Layer    |  GCP VMs, VPC, firewall rules
+---------------------------+
```

```
Terraform → Ansible → Kubernetes → Platform Services → ArgoCD (GitOps)
```

---

## Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform (GCP VMs, VPC, firewall) |
| Cluster bootstrap | Ansible + kubeadm |
| CNI | Cilium |
| GitOps | ArgoCD |
| Ingress / TLS | NGINX Ingress + Cert-Manager (Let's Encrypt) |
| Observability | Prometheus + Grafana |
| Object storage | MinIO AIStor (S3-compatible) |
| Streaming | Kafka via Strimzi (KRaft, no ZooKeeper) |
| Database | PostgreSQL 16 |
| Batch processing | Spark Operator |

---

## Cluster

- 3 GCP VMs — 1 control-plane + 2 workers (Ubuntu 22.04, 40 GB pd-balanced)
  - `k8s-cp-01` — control-plane, `e2-medium` (`10.50.0.21`)
  - `k8s-worker-01` — worker, `e2-standard-4`, static external IP (`10.50.0.22`)
  - `k8s-worker-02` — worker, `e2-standard-4` (`10.50.0.23`)
- Subnet: `10.50.0.0/24`
- Region: `europe-west1-b`

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
gcloud compute addresses create ml-lab-w01-ip \
  --region=europe-west1
```

Point your DNS A record to this IP (required for TLS cert issuance).

### Step 2 — Set secrets

Create the gitignored secrets file for Postgres:

```bash
cp ansible/roles/postgres/defaults/main.yml.example \
   ansible/roles/postgres/defaults/main.yml
# then edit and set postgres_password
```

MinIO credentials are set in `ansible/group_vars/all.yml` (`minio_secret_key`).

### Step 3 — Deploy everything

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

Plays run in order via `ansible/site.yml`:

| Play | Hosts | What it does |
|---|---|---|
| Base setup | all | OS prep, containerd, Kubernetes packages |
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
| PostgreSQL | control-plane | Postgres 16 + telemetry schema |
| MinIO | control-plane | AIStor object store |
| Spark Operator | control-plane | Spark job controller |
| ArgoCD bootstrap | control-plane | Apply ArgoCD project + app manifests |
| Dashboard API | control-plane | `api` namespace + DB schema init job |

Key variables in `ansible/group_vars/all.yml`:

| Variable | Value |
|---|---|
| `kubernetes_minor` | `v1.35` |
| `cilium_version` | `1.19.0` |
| `pod_cidr` | `10.244.0.0/16` |
| `service_cidr` | `10.96.0.0/12` |
| `platform_domain` | `ccmllab.mooo.com` |

---

## ArgoCD Applications

After bootstrap, ArgoCD manages the following apps from `network-telemetry-pipeline/data-pipeline`:

| App | Source path | Namespace |
|---|---|---|
| `kafka-topics` | `kafka/` | `kafka` |
| `spark-bronze` | `spark/bronze` | `spark` |
| `spark-gold` | `spark/gold` | `spark` |
| `dashboard-api` | `dashboard-api/` | `api` |

---

## Repository Structure

```
.
├── deploy.sh                   # One-shot deployment script
├── terraform/                  # GCP provisioning
│   ├── main.tf
│   └── variables.tf
└── ansible/                    # Cluster bootstrap + platform install
    ├── site.yml
    ├── group_vars/all.yml
    └── roles/
        ├── common/
        ├── containerd/
        ├── kubernetes/
        ├── cilium/
        ├── ingress_nginx/
        ├── cert_manager/
        ├── argocd/
        ├── monitoring/
        ├── ingress_routes/
        ├── storage_local_path/
        ├── kafka/
        ├── postgres/
        ├── minio/
        ├── spark_operator/
        └── dashboard_api/
```

---

## What This Demonstrates

- Infrastructure as Code (Terraform + Ansible)
- Self-managed Kubernetes cluster bootstrap with kubeadm
- Stateful workloads on Kubernetes (Kafka, MinIO, PostgreSQL)
- Observability with Prometheus & Grafana
- TLS automation with Cert-Manager + Let's Encrypt
- GitOps delivery with ArgoCD
- Multi-stage data pipeline (bronze → gold) with Spark
