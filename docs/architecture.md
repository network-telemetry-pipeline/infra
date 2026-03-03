# 🏗 System Architecture

## Layered Overview

Infrastructure Layer
- GCP VMs
- Networking
- Firewall rules

Cluster Layer
- Kubernetes (kubeadm)
- CNI (Cilium)
- StorageClass

Platform Layer
- NGINX Ingress
- Cert-Manager
- ArgoCD
- Prometheus + Grafana

Data Layer
- Kafka (Strimzi)
- MinIO (S3 storage)
- Spark Operator

Application Layer
- Python producer
- Spark Structured Streaming job

---

## Data Flow

Producer → Kafka → Spark → MinIO (S3)

---

## Kafka Architecture

- Strimzi Operator
- KRaft mode (no ZooKeeper)
- Single broker (lab setup)
- Internal + NodePort listener
- Advertised host configured to static IP

---

## MinIO Architecture

- StatefulSet
- NodePort service
- Console exposed via Ingress
- Used as:
  - Bronze storage
  - Spark checkpoint storage

---

## Spark Architecture

- Spark Operator (CRD-based deployment)
- Cluster mode
- ServiceAccount with RBAC
- Kafka + S3 connectors
- Structured Streaming
- Checkpointing enabled