# 🚀 Kubernetes Data & ML Platform Lab

End-to-end streaming data platform built on Kubernetes with infrastructure automation, GitOps, observability, and real-time data processing.

This project demonstrates a production-style data platform deployed on self-managed Kubernetes running on GCP VMs.

It includes:

- Infrastructure provisioning with Terraform
- Cluster automation with Ansible
- GitOps deployment via ArgoCD
- Kafka streaming ingestion
- Spark Structured Streaming
- S3 data lake storage (MinIO)
- Observability with Prometheus & Grafana

---

# 🏗 High-Level Architecture

Terraform → Ansible → Kubernetes Cluster → Platform Services → Data Platform → Streaming Pipeline

Detailed architecture: see [`docs/architecture.md`](docs/architecture.md)

---

# 🌍 Infrastructure

- 3 GCP VMs (1 control-plane, 2 workers)
- Static external IP
- Firewall rules (80, 443, Kafka NodePort)
- Fully automated via Terraform + Ansible

Details: [`docs/infrastructure.md`](docs/infrastructure.md)

---

# ☸️ Platform Services

- NGINX Ingress + TLS
- Cert-Manager
- ArgoCD (GitOps)
- Prometheus + Grafana
- Local Path StorageClass

---

# 🧱 Data Stack

- Kafka (Strimzi, KRaft mode)
- MinIO (S3-compatible object storage)
- Spark (Spark Operator)
- Python Kafka producer

Details: [`docs/pipeline.md`](docs/pipeline.md)

---

# 📡 Data Pipeline Overview

1. Python producer simulates router telemetry
2. Messages sent to Kafka topic `router.metrics.raw`
3. Spark Structured Streaming consumes Kafka
4. Data parsed & enriched
5. Parquet written to S3 Bronze layer
6. Checkpoints stored in S3

---

# 🧪 What This Project Demonstrates

- Infrastructure as Code
- Kubernetes cluster bootstrap
- Stateful systems on Kubernetes
- Real-time streaming architecture
- Distributed processing
- Data lake storage
- Observability integration
- Secure secret management

---

# 📈 Future Improvements

- Multi-broker Kafka cluster
- HA MinIO deployment
- Medallion architecture (Bronze/Silver/Gold)
- Delta Lake integration
- Airflow orchestration
- ML feature store integration

---

# 🏁 Deployment Flow

1. `terraform apply`
2. `ansible-playbook site.yml`
3. Deploy platform services (ArgoCD)
4. Deploy Kafka cluster
5. Deploy MinIO
6. Deploy SparkApplication
7. Start producer
8. Verify Parquet in S3

---

# 🧠 Why This Matters

This lab simulates real-world streaming architectures used in:

- IoT telemetry systems
- Network monitoring platforms
- Log aggregation pipelines
- Event-driven data platforms
- ML feature ingestion pipelines